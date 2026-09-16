#!/usr/bin/env python3
"""Expose owned skills and retire legacy hooks without replacing integrations."""

from __future__ import annotations

import json
import os
import tempfile
from pathlib import Path
from typing import Any


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


def remove_hook(
    config: dict[str, Any],
    event: str,
    hook_command: str,
) -> bool:
    hooks = config.get("hooks", {})
    if not isinstance(hooks, dict):
        raise ValueError("hooks must be a JSON object")
    groups = hooks.get(event, [])
    if not isinstance(groups, list):
        raise ValueError(f"hooks.{event} must be a JSON array")
    changed = False
    retained_groups = []
    for group in groups:
        if not isinstance(group, dict):
            retained_groups.append(group)
            continue
        handlers = group.get("hooks")
        if not isinstance(handlers, list):
            retained_groups.append(group)
            continue
        retained = [
            handler for handler in handlers
            if not (isinstance(handler, dict) and handler.get("command") == hook_command)
        ]
        if len(retained) != len(handlers):
            changed = True
            if retained:
                retained_groups.append({**group, "hooks": retained})
        else:
            retained_groups.append(group)
    if changed:
        if retained_groups:
            hooks[event] = retained_groups
        else:
            hooks.pop(event, None)
    return changed


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


def reconcile(product: str, path: Path) -> bool:
    config = load_object(path)
    changed = False
    changed |= remove_hook(config, "UserPromptSubmit", command(product, "prompt"))
    changed |= remove_hook(config, "PreToolUse", command(product, "tool"))
    changed |= remove_hook(config, "Stop", command(product, "lock"))
    if changed:
        write_atomic(path, config)
    return changed


def link_skills(source: Path, destinations: list[Path]) -> int:
    """Create only missing links; preflight all conflicts before writing any."""
    skills = sorted(path.parent for path in source.glob("*/SKILL.md"))
    if not skills:
        raise ValueError(f"No skills found in {source}")
    pending = []
    for destination in destinations:
        for skill in skills:
            target = destination / skill.name
            if target.exists() or target.is_symlink():
                if target.resolve() != skill.resolve():
                    raise ValueError(f"Refusing to replace existing skill: {target}")
            else:
                pending.append((target, skill))
    for target, skill in pending:
        target.parent.mkdir(parents=True, exist_ok=True)
        target.symlink_to(os.path.relpath(skill, target.parent), target_is_directory=True)
    return len(pending)


def main() -> None:
    user_home = Path.home()
    source = Path(__file__).resolve().parents[1] / ".agents" / "skills"
    count = link_skills(source, [
        user_home / ".claude" / "skills",
    ])
    print(f"skills: created {count} native discovery links")
    targets = {
        "claude": user_home / ".claude" / "settings.json",
        "codex": user_home / ".codex" / "hooks.json",
    }
    for product, path in targets.items():
        status = "removed owned gate hooks" if reconcile(product, path) else "no owned gate hooks"
        print(f"{product}: {status}")


if __name__ == "__main__":
    main()
