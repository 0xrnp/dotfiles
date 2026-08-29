#!/usr/bin/env bash
set -euo pipefail

H="$HOME"

test -r "$H/ai-standards/AGENTS.md"
test -r "$H/ai-standards/approve-phrases.txt"
test -r "$H/ai-standards/approval-gate.py"
test -x "$H/.cursor/hooks/gate-edit.sh"
test -x "$H/.cursor/hooks/gate-plan-approve.sh"
test -r "$H/.cursor/hooks/strip-cursor-attribution.sh"
test -r "$H/.agents/skills/using-skill-guide/SKILL.md"
command -v jq >/dev/null

python3 - "$H" <<'PY'
from __future__ import annotations

import hashlib
import json
import os
import subprocess
import sys
from pathlib import Path


home = Path(sys.argv[1])
standards = home / "ai-standards"
skills = home / ".agents" / "skills"
gate = standards / "approval-gate.py"

required_skills = {
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
    "python-engineering",
    "react-native",
    "rust-engineering",
    "schema-design",
    "self-review",
    "system-design",
    "terraform-engineering",
    "unslop",
    "using-skill-guide",
}

phrases = [
    line.strip()
    for line in (standards / "approve-phrases.txt").read_text().splitlines()
    if line.strip() and not line.lstrip().startswith("#")
]
assert phrases == ["gooo", "okgo", "noplan"], phrases

core = (standards / "AGENTS.md").read_text()
canonical = (standards / "AGENTS.md").resolve()
assert (home / ".codex" / "AGENTS.md").resolve() == canonical
assert (home / ".config" / "opencode" / "AGENTS.md").resolve() == canonical
for required in (
    "Plan, approve, edit",
    "Checkout gate",
    "Scope and impact",
    "Commits",
    "Pull requests",
    "Repository code outranks skills",
    "Use the approved message unchanged",
    "Use the approved title and body unchanged",
    "Do not use em dashes",
    "~/.agents/skills/using-skill-guide/SKILL.md",
    "last non-empty line",
    "Waiting to commit with the message above.",
    "Waiting to open the PR with the title/body above.",
):
    assert required in core, f"missing canonical standard: {required}"
for required in ("`WORKTREE`", "`MAIN`", "~/workspace/worktrees/<repo>/<name>/"):
    assert required in core, f"missing checkout gate requirement: {required}"

required_paths = [skills / name / "SKILL.md" for name in required_skills]
for path in [standards / "AGENTS.md", standards / "README.md", *required_paths]:
    text = path.read_text()
    assert "\u2014" not in text and "\u2013" not in text, f"em dash found in {path}"

found_skills = {path.parent.name for path in skills.glob("*/SKILL.md")}
missing = required_skills - found_skills
assert not missing, f"missing skills: {sorted(missing)}"
for name in required_skills:
    legacy = home / ".cursor" / "skills" / name
    assert not (legacy.is_symlink() and not legacy.exists()), f"broken legacy link: {legacy}"

for path in required_paths:
    lines = path.read_text().splitlines()
    assert lines and lines[0] == "---", f"missing frontmatter: {path}"
    end = lines.index("---", 1)
    metadata = {}
    for line in lines[1:end]:
        if ": " in line:
            key, value = line.split(": ", 1)
            metadata[key] = value
    assert metadata.get("name") == path.parent.name, f"name mismatch: {path}"
    assert metadata.get("description"), f"missing description: {path}"

pr_skill = (skills / "pr-authoring" / "SKILL.md").read_text()
for required in (
    "Preview gate",
    "--body-file",
    "--description",
    "Waiting to open the PR with the title/body above.",
    "no reviewer",
):
    assert required in pr_skill, f"missing PR workflow requirement: {required}"
assert "disable-model-invocation" not in pr_skill, "pr-authoring must allow ambient load"
commit_skill = (skills / "commit-authoring" / "SKILL.md").read_text()
for required in (
    "Preview gate",
    "complete staged diff",
    "Do not bypass hooks",
    "Waiting to commit with the message above.",
    "propose the exact `git add` paths",
):
    assert required in commit_skill, f"missing commit workflow requirement: {required}"
assert "disable-model-invocation" not in commit_skill, "commit-authoring must allow ambient load"
skill_guide = (skills / "using-skill-guide" / "SKILL.md").read_text()
assert "`commit-authoring`; in Homes also `homes-git`" in skill_guide
assert "`pr-authoring`; in Homes also `homes-git`" in skill_guide
assert "`homes-js-ts` and `homes-git`" in skill_guide
assert "`homes-flutter` and `homes-git`" in skill_guide
assert "Checkout gate" in skill_guide
homes_git = (skills / "homes-git" / "SKILL.md").read_text()
for required in (
    "Checkout gate",
    "~/workspace/homes/worktrees/<repo>/<name>/",
    "NO TICKET",
    "may share the same message",
):
    assert required in homes_git, f"missing homes-git requirement: {required}"

cursor_hooks = json.loads((home / ".cursor" / "hooks.json").read_text())
for event in ("preToolUse", "beforeShellExecution", "beforeMCPExecution", "beforeReadFile"):
    definitions = cursor_hooks["hooks"][event]
    assert definitions and all(item.get("failClosed") is True for item in definitions)
assert any(
    item.get("command") == "bash ./hooks/strip-cursor-attribution.sh"
    and item.get("matcher") == "Shell"
    for item in cursor_hooks["hooks"]["preToolUse"]
)
assert cursor_hooks["hooks"]["stop"][0]["command"].endswith("cursor lock")

def run(product: str, event: str, payload: object, raw: bool = False):
    value = payload if raw else json.dumps(payload)
    return subprocess.run(
        [sys.executable, str(gate), product, event],
        input=value,
        text=True,
        capture_output=True,
        check=False,
    )

def cursor_permission(event: str, payload: object, raw: bool = False) -> str:
    result = run("cursor", event, payload, raw=raw)
    assert result.returncode == 0, result.stderr
    return json.loads(result.stdout)["permission"]

session = f"check-{os.getpid()}"
digest = hashlib.sha256(f"cursor:{session}".encode()).hexdigest()
state = Path(os.environ.get("XDG_STATE_HOME", home / ".local" / "state")) / "ai-standards" / f"{digest}.json"

try:
    run("cursor", "prompt", {"prompt": "implement it", "conversation_id": session, "generation_id": "g1"})
    assert cursor_permission("edit", {"tool_name": "Write", "conversation_id": session, "generation_id": "g1"}) == "deny"

    run("cursor", "prompt", {"prompt": "please gooo", "conversation_id": session, "generation_id": "g2"})
    assert cursor_permission("edit", {"tool_name": "Write", "conversation_id": session, "generation_id": "g2"}) == "deny"

    run("cursor", "prompt", {"prompt": "gooo please", "conversation_id": session, "generation_id": "g2b"})
    assert cursor_permission("edit", {"tool_name": "Write", "conversation_id": session, "generation_id": "g2b"}) == "deny"

    run("cursor", "prompt", {"prompt": "GoOo", "conversation_id": session, "generation_id": "g3"})
    assert cursor_permission("edit", {"tool_name": "Write", "conversation_id": session, "generation_id": "g3"}) == "allow"
    run("cursor", "lock", {"conversation_id": session, "generation_id": "g3"})
    assert cursor_permission("edit", {"tool_name": "Write", "conversation_id": session, "generation_id": "g3"}) == "deny"

    run(
        "cursor",
        "prompt",
        {
            "prompt": "MAIN\nNO TICKET\ngooo",
            "conversation_id": session,
            "generation_id": "g3b",
        },
    )
    assert cursor_permission("edit", {"tool_name": "Write", "conversation_id": session, "generation_id": "g3b"}) == "allow"
    run("cursor", "lock", {"conversation_id": session, "generation_id": "g3b"})

    run("cursor", "prompt", {"prompt": "new request", "conversation_id": session, "generation_id": "g4"})
    assert cursor_permission("edit", {"tool_name": "Write", "conversation_id": session, "generation_id": "g4"}) == "deny"

    assert cursor_permission("shell", {"command": "git status"}) == "allow"
    assert cursor_permission("shell", {"command": "git branch feature"}) == "deny"
    assert cursor_permission("shell", {"command": "python3 script.py"}) == "deny"
    assert cursor_permission("mcp", {"tool_name": "get_input_schema"}) == "allow"
    assert cursor_permission("mcp", {"tool_name": "update_issue"}) == "deny"
    assert cursor_permission("edit", "{", raw=True) == "deny"
finally:
    state.unlink(missing_ok=True)

for product in ("claude", "codex"):
    product_session = f"{session}-{product}"
    product_digest = hashlib.sha256(f"{product}:{product_session}".encode()).hexdigest()
    product_state = (
        Path(os.environ.get("XDG_STATE_HOME", home / ".local" / "state"))
        / "ai-standards"
        / f"{product_digest}.json"
    )
    try:
        run(product, "prompt", {"prompt": "implement it", "session_id": product_session})
        assert run(product, "tool", {"tool_name": "Write", "session_id": product_session}).returncode == 2
        run(product, "prompt", {"prompt": "gooo", "session_id": product_session})
        assert run(product, "tool", {"tool_name": "Write", "session_id": product_session}).returncode == 0
        run(product, "lock", {"session_id": product_session})
        assert run(product, "tool", {"tool_name": "Write", "session_id": product_session}).returncode == 2
        run(product, "prompt", {"prompt": "next task", "session_id": product_session})
        assert run(product, "tool", {"tool_name": "Write", "session_id": product_session}).returncode == 2
    finally:
        product_state.unlink(missing_ok=True)

injected = subprocess.check_output(
    [str(home / ".cursor" / "hooks" / "inject-standards.sh")],
    input="{}",
    text=True,
)
context = json.loads(injected)["additional_context"]
assert "Rudra's agent standards" in context
assert "gooo" in context
assert "using-skill-guide" in context

for product, path in (
    ("claude", home / ".claude" / "settings.json"),
    ("codex", home / ".codex" / "hooks.json"),
):
    config = json.loads(path.read_text())
    commands = {
        handler.get("command")
        for groups in config.get("hooks", {}).values()
        for group in groups
        if isinstance(group, dict)
        for handler in group.get("hooks", [])
        if isinstance(handler, dict)
    }
    assert f'python3 "$HOME/ai-standards/approval-gate.py" {product} prompt' in commands
    assert f'python3 "$HOME/ai-standards/approval-gate.py" {product} tool' in commands
    assert f'python3 "$HOME/ai-standards/approval-gate.py" {product} lock' in commands

sanitizer_payload = {
    "tool_name": "Shell",
    "tool_input": {
        "command": (
            "git commit -m 'fix: example\n\n"
            "Co-authored-by: Cursor <cursoragent@cursor.com>'"
        ),
        "working_directory": "/tmp/example",
        "description": "Example command",
    },
}
sanitized = json.loads(
    subprocess.check_output(
        ["bash", str(home / ".cursor" / "hooks" / "strip-cursor-attribution.sh")],
        input=json.dumps(sanitizer_payload),
        text=True,
    )
)
assert sanitized["permission"] == "allow"
assert "cursoragent@cursor.com" not in sanitized["updated_input"]["command"]
assert sanitized["updated_input"]["working_directory"] == "/tmp/example"
assert sanitized["updated_input"]["description"] == "Example command"

unchanged = json.loads(
    subprocess.check_output(
        ["bash", str(home / ".cursor" / "hooks" / "strip-cursor-attribution.sh")],
        input=json.dumps(
            {
                "tool_name": "Shell",
                "tool_input": {"command": "git status"},
            }
        ),
        text=True,
    )
)
assert unchanged == {"permission": "allow"}

shell_payload = {
    "command": "git commit -m x --trailer Co-authored-by: Cursor <agent@cursor.com>",
    "conversation_id": session,
    "generation_id": "g5",
}
run("cursor", "prompt", {"prompt": "gooo", "conversation_id": session, "generation_id": "g5"})
shell = subprocess.check_output(
    [str(home / ".cursor" / "hooks" / "gate-shell.sh")],
    input=json.dumps(shell_payload),
    text=True,
)
assert '"deny"' in shell
state.unlink(missing_ok=True)

print("OK")
PY
