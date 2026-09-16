#!/usr/bin/env bash
set -euo pipefail

export PATH="/opt/homebrew/bin:$PATH"
H="$HOME"

test -r "$H/ai-standards/AGENTS.md"
test -r "$H/.pi/agent/extensions/ai-standards.ts"
test -x "$H/.cursor/hooks/gate-shell.sh"
test -x "$H/.cursor/hooks/gate-mcp.sh"
test -x "$H/.cursor/hooks/gate-read.sh"
test -r "$H/.cursor/hooks/strip-cursor-attribution.sh"
test -r "$H/.agents/skills/using-skill-guide/SKILL.md"
command -v jq >/dev/null
command -v node >/dev/null

python3 - "$H" <<'PY'
from __future__ import annotations

import importlib.util
import json
import subprocess
import sys
import tempfile
from pathlib import Path


home = Path(sys.argv[1])
standards = home / "ai-standards"
skills = home / ".agents" / "skills"
cursor = home / ".cursor"

required_skills = {
    "add-pr-comments",
    "blast-radius",
    "commit-authoring",
    "contract-design",
    "dart-flutter-engineering",
    "homes-flutter",
    "homes-git",
    "homes-js-ts",
    "js-ts-engineering",
    "mongo-aggregations",
    "pr-authoring",
    "pr-review",
    "pr-review-and-comment",
    "python-engineering",
    "react-native",
    "rust-engineering",
    "schema-design",
    "security-hardening",
    "self-review",
    "system-design",
    "systematic-debugging",
    "terraform-engineering",
    "unslop",
    "using-skill-guide",
    "verification-before-completion",
}

canonical = (standards / "AGENTS.md").resolve()
for target in (
    home / ".codex" / "AGENTS.md",
    home / ".config" / "opencode" / "AGENTS.md",
    home / ".pi" / "agent" / "AGENTS.md",
):
    assert target.resolve() == canonical, f"wrong canonical policy: {target}"

core = canonical.read_text()
for required in (
    "Checkout placement",
    "Plan, then implement",
    "Scope and impact",
    "Commits",
    "Pull requests",
    "No special token or final-line syntax is needed",
    "Waiting to commit with the message above.",
    "Waiting to open the PR with the title/body above.",
    "Waiting to post N inline comment(s) on",
):
    assert required in core, f"missing standard: {required}"
assert "gooo" not in core
assert "last non-empty line" not in core

found = {path.parent.name for path in skills.glob("*/SKILL.md")}
assert not required_skills - found, f"missing skills: {sorted(required_skills - found)}"
for path in [
    standards / "AGENTS.md",
    standards / "README.md",
    standards / "cursor-user-rules.md",
    *(skills / name / "SKILL.md" for name in required_skills),
]:
    content = path.read_text()
    assert "\u2014" not in content and "\u2013" not in content, f"dash found: {path}"

for name in required_skills:
    path = skills / name / "SKILL.md"
    lines = path.read_text().splitlines()
    assert lines[0] == "---", f"missing frontmatter: {path}"
    end = lines.index("---", 1)
    frontmatter = "\n".join(lines[1:end])
    assert f"name: {name}" in frontmatter, f"name mismatch: {path}"
    assert "description:" in frontmatter, f"missing description: {path}"
    legacy = cursor / "skills" / name
    assert not (legacy.is_symlink() and not legacy.exists()), f"broken skill link: {legacy}"

guide = (skills / "using-skill-guide" / "SKILL.md").read_text()
assert "Checkout gate" not in guide
assert "`systematic-debugging`" in guide
assert "`verification-before-completion`" in guide
assert "`security-hardening`" in guide
homes_git = (skills / "homes-git" / "SKILL.md").read_text()
assert "Checkout gate" not in homes_git
assert "~/workspace/homes/worktrees/<repo>/<name>/" in homes_git

config = json.loads((cursor / "hooks.json").read_text())
hooks = config["hooks"]
assert "beforeSubmitPrompt" not in hooks
assert "stop" not in hooks
assert not any("gate-edit.sh" in item.get("command", "") for item in hooks["preToolUse"])
for event in ("preToolUse", "beforeShellExecution", "beforeMCPExecution", "beforeReadFile"):
    assert hooks[event] and all(item.get("failClosed") is True for item in hooks[event])
assert hooks["beforeShellExecution"][0]["command"] == "./hooks/gate-shell.sh"
assert hooks["beforeMCPExecution"][0]["command"] == "./hooks/gate-mcp.sh"
assert hooks["beforeReadFile"][0]["command"] == "./hooks/gate-read.sh"
assert any("strip-cursor-attribution.sh" in item["command"] for item in hooks["preToolUse"])

injected = subprocess.check_output(
    [str(cursor / "hooks" / "inject-standards.sh")],
    input="{}",
    text=True,
)
context = json.loads(injected)["additional_context"]
assert "Plan, then implement" in context
assert "gooo" not in context

spec = importlib.util.spec_from_file_location("agent_hooks", standards / "install-agent-hooks.py")
assert spec is not None and spec.loader is not None
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)

with tempfile.TemporaryDirectory(prefix="agent-hooks-check-") as directory:
    fixture = Path(directory) / "settings.json"
    fixture.write_text(json.dumps({"hooks": {
        "UserPromptSubmit": [{"hooks": [
            {"command": module.command("claude", "prompt")},
            {"command": "third-party prompt"},
        ]}],
        "PreToolUse": [
            {"hooks": [{"command": module.command("claude", "tool")}]},
            {"hooks": [{"command": "third-party tool"}]},
        ],
        "Stop": [{"hooks": [
            {"command": module.command("claude", "lock")},
            {"command": "third-party stop"},
        ]}],
    }}))
    assert module.reconcile("claude", fixture)
    assert not module.reconcile("claude", fixture)
    kept = json.loads(fixture.read_text())["hooks"]
    assert kept["UserPromptSubmit"][0]["hooks"] == [{"command": "third-party prompt"}]
    assert kept["PreToolUse"] == [{"hooks": [{"command": "third-party tool"}]}]
    assert kept["Stop"][0]["hooks"] == [{"command": "third-party stop"}]

for product in ("claude", "codex"):
    live = json.loads((home / f".{product}" / ("settings.json" if product == "claude" else "hooks.json")).read_text())
    content = json.dumps(live)
    for event in ("prompt", "tool", "lock"):
        assert module.command(product, event) not in content, f"legacy {product} gate remains"

def hook_decision(name: str, payload: str) -> str:
    result = subprocess.run(
        [str(cursor / "hooks" / name)],
        input=payload,
        text=True,
        capture_output=True,
        check=False,
    )
    assert result.returncode == 0, result.stderr
    return json.loads(result.stdout)["permission"]

def shell(command: str) -> str:
    return hook_decision("gate-shell.sh", json.dumps({"command": command}))

assert shell("touch local.txt") == "allow"
assert shell("git reset --hard") == "deny"
assert shell("rm -rf /") == "deny"
assert shell("rm -rf docs/ripple") == "ask"
assert shell("git commit -m change") == "ask"
assert shell("git commit -m change --trailer Co-authored-by: Cursor <agent@cursor.com>") == "deny"
assert shell("cat .env") == "ask"
assert hook_decision("gate-shell.sh", "{") == "deny"
assert hook_decision("gate-mcp.sh", json.dumps({"tool_name": "list_issues"})) == "allow"
assert hook_decision("gate-mcp.sh", json.dumps({"tool_name": "update_issue"})) == "ask"
assert hook_decision("gate-mcp.sh", "{") == "deny"
assert hook_decision("gate-read.sh", json.dumps({"file_path": ".env"})) == "deny"
assert hook_decision("gate-read.sh", json.dumps({"file_path": ".env.example"})) == "allow"

sanitized = subprocess.check_output(
    ["bash", str(cursor / "hooks" / "strip-cursor-attribution.sh")],
    input=json.dumps({"tool_input": {
        "command": "git commit -m change Co-authored-by: Cursor <cursoragent@cursor.com>",
        "working_directory": "/tmp/example",
    }}),
    text=True,
)
updated = json.loads(sanitized)["updated_input"]
assert "cursoragent@cursor.com" not in updated["command"]
assert updated["working_directory"] == "/tmp/example"

print("OK")
PY

node --experimental-strip-types --test "$H/ai-standards/pi-approval.test.mjs"
