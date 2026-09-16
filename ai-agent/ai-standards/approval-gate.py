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
READ_ONLY_BKT_PR = {"checks", "diff", "list", "view"}
READ_ONLY_BKT_PR_COMMENTS_MUTATIONS = {"delete", "reopen", "resolve", "rm"}
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
    "pi",
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


def write_session_state(product: str, data: dict[str, Any], *, approved: bool) -> None:
    state = state_path(product, data)
    if state is None:
        return
    STATE_DIR.mkdir(mode=0o700, parents=True, exist_ok=True)
    payload = {
        "product": product,
        "generation_id": generation_id(data) if approved else "",
        "approved": approved,
    }
    state.write_text(json.dumps(payload), encoding="utf-8")
    state.chmod(0o600)


def prompt_bound(product: str, data: dict[str, Any]) -> bool:
    """True when a prompt or lock event already bound this session identity."""
    state = state_path(product, data)
    return state is not None and state.is_file()


def relock_or_approve(product: str, data: dict[str, Any]) -> bool:
    state = state_path(product, data)
    if state is None:
        return False

    prompt = data.get("prompt")
    approved = isinstance(prompt, str) and prompt_approves(prompt)
    write_session_state(product, data, approved=approved)
    return approved


def payload_grants_approval(
    payload: dict[str, Any], current_generation: str, direct_match: bool
) -> bool:
    if payload.get("approved") is False:
        return False
    approved_generation = payload.get("generation_id")
    if not isinstance(approved_generation, str):
        approved_generation = ""
    # Legacy approve files omit "approved" and only store generation_id.
    if "approved" in payload and payload.get("approved") is not True:
        return False
    if current_generation:
        return approved_generation == current_generation or (
            direct_match and approved_generation == ""
        )
    return direct_match and approved_generation == ""


def is_approved(product: str, data: dict[str, Any]) -> bool:
    state = state_path(product, data)
    candidates: list[Path] = []
    if state is not None:
        candidates.append(state)
    # Cursor prompt vs tool payloads can disagree on conversation_id. Only use
    # the generation ID fallback for Cursor and never share approvals between
    # products.
    current_generation = generation_id(data)
    if product == "cursor" and current_generation and STATE_DIR.is_dir():
        candidates.extend(sorted(STATE_DIR.glob("*.json")))

    seen: set[Path] = set()
    for path in candidates:
        if path in seen or not path.is_file():
            continue
        seen.add(path)
        try:
            payload = json.loads(path.read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError):
            continue
        if not isinstance(payload, dict) or payload.get("product") != product:
            continue
        direct_match = state is not None and path == state
        if payload_grants_approval(payload, current_generation, direct_match):
            return True
    return False


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
    if executable == "bkt":
        return _is_read_only_bkt(parts)
    return False


def _is_read_only_bkt(parts: list[str]) -> bool:
    if len(parts) == 2 and parts[1] in {"--version", "-V", "version"}:
        return True
    if len(parts) < 2:
        return False
    if parts[1] == "auth" and len(parts) >= 3 and parts[2] == "status":
        return True
    if parts[1] != "pr" or len(parts) < 3:
        return False
    subcommand = parts[2]
    if subcommand in READ_ONLY_BKT_PR:
        return True
    if subcommand == "comments":
        if len(parts) >= 4 and parts[3] in READ_ONLY_BKT_PR_COMMENTS_MUTATIONS:
            return False
        return True
    return False


def tool_name(data: dict[str, Any]) -> str:
    value = (
        data.get("tool_name") or data.get("toolName")
        or data.get("tool") or data.get("name")
    )
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


SOFT_ADVISORY = (
    "Plan-first still applies, but no bound prompt reached the approval hook "
    "for this session (common under Cursor ACP in Zed). The hard gate cannot "
    "verify a last-line token here. Present a file-level plan and wait for an "
    "explicit go-ahead before mutating."
)


def cursor_result(allowed: bool, message: str, *, advisory: str = "") -> None:
    if allowed:
        if advisory:
            print(json.dumps({"permission": "allow", "agent_message": advisory}))
        else:
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
            "usage: approval-gate.py <cursor|claude|codex|pi> "
            "<prompt|lock|tool|edit|shell|mcp>",
            file=sys.stderr,
        )
        return 2

    product, event = sys.argv[1:3]
    data = load_input()
    # SDK prompts can contain replayed history, not the raw Pi user message.
    # Local Cursor hooks must consult Pi's delivered-input state instead.
    pi_session = (
        os.environ.get("AI_STANDARDS_PI_SESSION", "") if product == "cursor" else ""
    )
    if pi_session:
        if event in {"prompt", "lock"}:
            print("{}")
            return 0
        read_only = event == "shell" and is_read_only_shell(command_from(data))
        if event == "tool":
            read_only = tool_name(data) in {"read", "readfile", "glob", "grep", "ls"}
            if tool_name(data) in SHELL_TOOLS:
                read_only = is_read_only_shell(command_from(data))
        allowed = bool(data) and (
            read_only or is_approved("pi", {"session_id": pi_session})
        )
        cursor_result(
            allowed,
            "Pi plan-first gate: wait for a delivered human approval token before modifying state.",
        )
        return 0

    if event == "prompt":
        relock_or_approve(product, data)
        if product == "cursor":
            print("{}")
        return 0
    if event == "lock":
        write_session_state(product, data, approved=False)
        if product == "cursor":
            print("{}")
        return 0

    message = (
        "Plan-first gate: this action can modify state. Present the goal, files, "
        "concrete changes, exclusions, assumptions, and risks, then wait for a "
        "approval token on the last non-empty line of the user message."
    )
    # Hard when a prompt/lock already bound this session. Soft fail-open only for
    # Cursor when a tool carries a session id but no prompt bound it (ACP in Zed).
    # Claude/Codex/Pi always deliver bound prompts when hooks run; keep them hard.
    needs_approval = requires_approval(event, data)
    approved = is_approved(product, data)
    soft = (
        product == "cursor"
        and bool(data)
        and needs_approval
        and not approved
        and bool(session_id(data))
        and not prompt_bound(product, data)
    )
    allowed = bool(data) and (not needs_approval or approved or soft)

    if product == "cursor":
        cursor_result(allowed, message, advisory=SOFT_ADVISORY if soft else "")
        return 0
    if allowed:
        if soft:
            print(SOFT_ADVISORY, file=sys.stderr)
        return 0
    print(message, file=sys.stderr)
    return 2


if __name__ == "__main__":
    raise SystemExit(main())