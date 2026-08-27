#!/usr/bin/env bash
set -euo pipefail

H="$HOME"

test -r "$H/ai-standards/AGENTS.md"
test -r "$H/ai-standards/approve-phrases.txt"
test -r "$H/ai-standards/approval-gate.py"
test -x "$H/.cursor/hooks/gate-edit.sh"
test -x "$H/.cursor/hooks/gate-plan-approve.sh"
test -r "$H/.agents/skills/using-skill-guide/SKILL.md"

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
    "contract-design",
    "dart-flutter-engineering",
    "homes-flutter",
    "homes-git",
    "homes-js-ts",
    "js-ts-engineering",
    "mongo-aggregations",
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
    "Scope and impact",
    "Repository code outranks skills",
    "Do not use em dashes",
    "~/.agents/skills/using-skill-guide/SKILL.md",
):
    assert required in core, f"missing canonical standard: {required}"

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

cursor_hooks = json.loads((home / ".cursor" / "hooks.json").read_text())
for event in ("preToolUse", "beforeShellExecution", "beforeMCPExecution", "beforeReadFile"):
    definitions = cursor_hooks["hooks"][event]
    assert definitions and all(item.get("failClosed") is True for item in definitions)
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

    run("cursor", "prompt", {"prompt": "GoOo", "conversation_id": session, "generation_id": "g3"})
    assert cursor_permission("edit", {"tool_name": "Write", "conversation_id": session, "generation_id": "g3"}) == "allow"
    run("cursor", "lock", {"conversation_id": session, "generation_id": "g3"})
    assert cursor_permission("edit", {"tool_name": "Write", "conversation_id": session, "generation_id": "g3"}) == "deny"

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
