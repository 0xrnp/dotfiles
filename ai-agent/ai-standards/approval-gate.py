#!/usr/bin/env python3
"""Cross-agent plan approval gate using only the Python standard library."""

from __future__ import annotations

import hashlib
import json
import os
import re
import shlex
import sys
from pathlib import Path
from typing import Any


HOME = Path.home()
PHRASES_PATH = HOME / "ai-standards" / "approve-phrases.txt"
STATE_DIR = Path(
    os.environ.get("XDG_STATE_HOME", HOME / ".local" / "state")
) / "ai-standards"

EDIT_TOOLS = {
    "apply_patch",
    "applypatch",
    "createfile",
    "delete",
    "deletefile",
    "edit",
    "editnotebook",
    "move",
    "multiedit",
    "notebook",
    "notebookedit",
    "replace",
    "searchreplace",
    "strreplace",
    "write",
}
SHELL_TOOLS = {"bash", "powershell", "shell"}
MCP_MUTATION_WORDS = {
    "auth",
    "create",
    "delete",
    "deploy",
    "drop",
    "execute",
    "insert",
    "patch",
    "post",
    "publish",
    "put",
    "remove",
    "mutation",
    "send",
    "update",
    "write",
}
READ_ONLY_COMMANDS = {"file", "ls", "pwd", "rg", "stat", "type", "wc", "which"}
READ_ONLY_GIT = {
    "diff",
    "grep",
    "log",
    "ls-files",
    "rev-parse",
    "show",
    "status",
}
VERSION_COMMANDS = {
    "bkt",
    "bun",
    "cargo",
    "claude",
    "codex",
    "cursor-agent",
    "dart",
    "deno",
    "dotnet",
    "elixir",
    "flutter",
    "gh",
    "git",
    "java",
    "javac",
    "kotlin",
    "mix",
    "node",
    "npm",
    "opencode",
    "php",
    "pnpm",
    "python",
    "python3",
    "ruby",
    "rustc",
    "swift",
    "terraform",
    "terragrunt",
    "tofu",
    "uv",
    "yarn",
    "zig",
}


def load_input() -> dict[str, Any]:
    try:
        value = json.load(sys.stdin)
    except Exception:
        return {}
    return value if isinstance(value, dict) else {}


def phrases() -> set[str]:
    try:
        lines = PHRASES_PATH.read_text(encoding="utf-8").splitlines()
    except OSError:
        return set()
    return {
        line.strip().casefold()
        for line in lines
        if line.strip() and not line.lstrip().startswith("#")
    }


def session_id(data: dict[str, Any]) -> str:
    value = data.get("conversation_id") or data.get("session_id")
    return value if isinstance(value, str) else ""


def generation_id(data: dict[str, Any]) -> str:
    value = data.get("generation_id")
    return value if isinstance(value, str) else ""


def state_path(product: str, data: dict[str, Any]) -> Path | None:
    identity = session_id(data)
    if not identity:
        return None
    digest = hashlib.sha256(f"{product}:{identity}".encode()).hexdigest()
    return STATE_DIR / f"{digest}.json"


def prompt_approves(prompt: str) -> bool:
    """True when the last non-empty line is an approval phrase."""
    lines = [line.strip() for line in prompt.splitlines() if line.strip()]
    return bool(lines) and lines[-1].casefold() in phrases()


def relock_or_approve(product: str, data: dict[str, Any]) -> bool:
    state = state_path(product, data)
    if state is None:
        return False

    state.unlink(missing_ok=True)
    prompt = data.get("prompt")
    if not isinstance(prompt, str) or not prompt_approves(prompt):
        return False

    STATE_DIR.mkdir(mode=0o700, parents=True, exist_ok=True)
    payload = {"generation_id": generation_id(data)}
    state.write_text(json.dumps(payload), encoding="utf-8")
    state.chmod(0o600)
    return True


def is_approved(product: str, data: dict[str, Any]) -> bool:
    state = state_path(product, data)
    if state is None:
        return False
    try:
        payload = json.loads(state.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError):
        return False

    current_generation = generation_id(data)
    approved_generation = payload.get("generation_id")
    if current_generation:
        return approved_generation == current_generation
    return approved_generation == ""


def command_from(data: dict[str, Any]) -> str:
    direct = data.get("command")
    if isinstance(direct, str):
        return direct
    tool_input = data.get("tool_input")
    if isinstance(tool_input, dict):
        nested = tool_input.get("command")
        if isinstance(nested, str):
            return nested
    return ""


def is_read_only_shell(command: str) -> bool:
    if not command or re.search(r"[;&|><`\n]|\$\(", command):
        return False
    try:
        parts = shlex.split(command)
    except ValueError:
        return False
    if not parts:
        return False

    executable = Path(parts[0]).name
    if executable in READ_ONLY_COMMANDS:
        return True
    if executable == "command":
        return len(parts) >= 3 and parts[1] == "-v"
    if executable == "git":
        if len(parts) < 2 or any(part.startswith("--output") for part in parts[2:]):
            return False
        subcommand, arguments = parts[1], parts[2:]
        if subcommand in READ_ONLY_GIT:
            return True
        if subcommand == "branch":
            return not arguments or all(
                argument in {"--list", "--show-current", "-l"} for argument in arguments
            )
        if subcommand == "remote":
            return not arguments or arguments in [["-v"], ["-vv"]]
        if subcommand == "tag":
            return not arguments or all(
                argument in {"--list", "-l"} for argument in arguments
            )
        return False
    if (
        executable in VERSION_COMMANDS
        and len(parts) == 2
        and parts[1] in {"--version", "-V", "version"}
    ):
        return True
    if executable == "go" and parts == ["go", "version"]:
        return True
    return False


def tool_name(data: dict[str, Any]) -> str:
    value = data.get("tool_name") or data.get("tool") or data.get("name")
    return value.casefold() if isinstance(value, str) else ""


def has_mutation_word(name: str) -> bool:
    words = set(re.split(r"[^a-z0-9]+", name))
    return bool(words & MCP_MUTATION_WORDS) or any(
        name.startswith(word) for word in MCP_MUTATION_WORDS
    )


def requires_approval(event: str, data: dict[str, Any]) -> bool:
    if event == "edit":
        return True
    if event == "shell":
        return not is_read_only_shell(command_from(data))
    if event == "mcp":
        return has_mutation_word(tool_name(data))

    name = tool_name(data)
    if name in SHELL_TOOLS:
        return not is_read_only_shell(command_from(data))
    if name.startswith("mcp__") or name.startswith("mcp:"):
        return has_mutation_word(name)
    normalized = re.sub(r"[^a-z0-9_]", "", name)
    return normalized in EDIT_TOOLS


def cursor_result(allowed: bool, message: str) -> None:
    if allowed:
        print('{"permission":"allow"}')
        return
    print(
        json.dumps(
            {
                "permission": "deny",
                "user_message": message,
                "agent_message": (
                    "Blocked by the personal plan-first gate. Present a "
                    "file-level plan and wait for an approval token "
                    "(last non-empty line of the user message)."
                ),
            }
        )
    )


def main() -> int:
    if len(sys.argv) != 3:
        print(
            "usage: approval-gate.py <cursor|claude|codex> "
            "<prompt|lock|tool|edit|shell|mcp>",
            file=sys.stderr,
        )
        return 2

    product, event = sys.argv[1:3]
    data = load_input()

    if event == "prompt":
        relock_or_approve(product, data)
        if product == "cursor":
            print("{}")
        return 0
    if event == "lock":
        state = state_path(product, data)
        if state is not None:
            state.unlink(missing_ok=True)
        if product == "cursor":
            print("{}")
        return 0

    allowed = bool(data) and (
        not requires_approval(event, data) or is_approved(product, data)
    )
    message = (
        "Plan-first gate: this action can modify state. Present the goal, files, "
        "concrete changes, exclusions, assumptions, and risks, then wait for a "
        "approval token on the last non-empty line of the user message."
    )

    if product == "cursor":
        cursor_result(allowed, message)
        return 0
    if allowed:
        return 0
    print(message, file=sys.stderr)
    return 2


if __name__ == "__main__":
    raise SystemExit(main())
