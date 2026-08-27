#!/usr/bin/env python3
"""Merge personal approval hooks without replacing third-party configuration."""

from __future__ import annotations

import json
import os
import tempfile
from pathlib import Path
from typing import Any


HOME = Path.home()
GATE = '$HOME/ai-standards/approval-gate.py'


def command(product: str, event: str) -> str:
    return f'python3 "{GATE}" {product} {event}'


def load_object(path: Path) -> dict[str, Any]:
    if not path.exists():
        return {}
    value = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(value, dict):
        raise ValueError(f"{path} must contain a JSON object")
    return value


def add_hook(
    config: dict[str, Any],
    event: str,
    hook_command: str,
) -> bool:
    hooks = config.setdefault("hooks", {})
    if not isinstance(hooks, dict):
        raise ValueError("hooks must be a JSON object")
    groups = hooks.setdefault(event, [])
    if not isinstance(groups, list):
        raise ValueError(f"hooks.{event} must be a JSON array")

    for group in groups:
        if not isinstance(group, dict):
            continue
        handlers = group.get("hooks")
        if not isinstance(handlers, list):
            continue
        if any(
            isinstance(handler, dict)
            and handler.get("command") == hook_command
            for handler in handlers
        ):
            return False

    groups.append(
        {
            "hooks": [
                {
                    "type": "command",
                    "command": hook_command,
                    "timeout": 5,
                }
            ]
        }
    )
    return True


def write_atomic(path: Path, config: dict[str, Any]) -> None:
    path.parent.mkdir(mode=0o700, parents=True, exist_ok=True)
    mode = path.stat().st_mode & 0o777 if path.exists() else 0o600
    content = json.dumps(config, indent=2, ensure_ascii=False) + "\n"
    with tempfile.NamedTemporaryFile(
        "w",
        encoding="utf-8",
        dir=path.parent,
        delete=False,
    ) as handle:
        handle.write(content)
        temporary = Path(handle.name)
    temporary.chmod(mode)
    os.replace(temporary, path)


def install(product: str, path: Path) -> bool:
    config = load_object(path)
    changed = False
    changed |= add_hook(config, "UserPromptSubmit", command(product, "prompt"))
    changed |= add_hook(config, "PreToolUse", command(product, "tool"))
    changed |= add_hook(config, "Stop", command(product, "lock"))
    if changed:
        write_atomic(path, config)
    return changed


def main() -> None:
    targets = {
        "claude": HOME / ".claude" / "settings.json",
        "codex": HOME / ".codex" / "hooks.json",
    }
    for product, path in targets.items():
        status = "updated" if install(product, path) else "already configured"
        print(f"{product}: {status}")


if __name__ == "__main__":
    main()
