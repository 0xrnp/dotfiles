#!/usr/bin/env python3
"""Run existing repository checks for files an agent changed during a turn.

A session-start snapshot of the working tree is compared at each stop, so only
files that changed during the turn select checks. Pre-existing dirty files and
question-only turns run nothing. This is a quality gate, not a safety boundary:
every internal error lets the agent finish.

Usage: verify-turn.py <claude|codex|cursor> <start|stop>  (hook JSON on stdin)
"""

from __future__ import annotations

import json
import os
import re
import shutil
import subprocess
import sys
import tempfile
import time
from pathlib import Path
from typing import Any, Callable, Union

# Hooks run repository scripts without a permission prompt, so only repositories
# under these roots are checked.
TRUSTED_ROOTS = ("~/workspace", "~/dotfiles")
CHECK_TIMEOUT = 150
TOTAL_BUDGET = 400
REVIEW_THRESHOLD = 3
TAIL_LINES = 40
TAIL_CHARS = 3000
STATE_TTL = 14 * 24 * 3600

TYPECHECK_SCRIPTS = ("typecheck", "type-check", "check-types", "types:check")
LINT_SCRIPTS = ("lint:check", "lint")
# A hook must never rewrite files, so scripts that fix or format are skipped.
WRITING_SCRIPT = re.compile(r"\bfix\b|--write\b")

LANGUAGES: dict[str, tuple[tuple[str, ...], tuple[str, ...], tuple[str, ...]]] = {
    # language: (source suffixes, other trigger names, project manifests)
    "js": (
        (".ts", ".tsx", ".js", ".jsx", ".mjs", ".cjs", ".mts", ".cts"),
        ("package.json",),
        ("package.json",),
    ),
    "python": (
        (".py", ".pyi"),
        ("pyproject.toml", "ruff.toml", ".ruff.toml"),
        ("pyproject.toml", "ruff.toml", ".ruff.toml"),
    ),
    "go": ((".go",), ("go.mod", "go.sum"), ("go.mod",)),
    "rust": ((".rs",), ("Cargo.toml", "Cargo.lock"), ("Cargo.toml",)),
    "dart": ((".dart",), ("pubspec.yaml", "analysis_options.yaml"), ("pubspec.yaml",)),
}

FIX_GUIDANCE = (
    "Fix failures caused by this turn's changes and re-run the failing command. "
    "Do not weaken lint, type, or test configuration or add ignore comments to "
    "pass. If a failure is pre-existing and outside this change, leave it and "
    "report it as a residual risk. Then finish with the report from "
    "`verification-before-completion`."
)
REVIEW_GUIDANCE = (
    "Before finishing: run targeted tests for the changed behavior "
    "(`verification-before-completion`) and review the full diff with "
    "`self-review`, including its independent review pass by a fresh subagent "
    "where this host supports one. Fix confirmed findings within scope. If this "
    "turn already did that, end with the existing report without repeating work."
)

Snapshot = dict[str, Any]
Check = tuple[str, list[str]]
CheckPlan = Union[list[Check], str]


def git(root: Path, *args: str) -> str:
    result = subprocess.run(
        ["git", "-C", str(root), *args],
        capture_output=True,
        text=True,
        errors="surrogateescape",
        stdin=subprocess.DEVNULL,
        check=False,
    )
    return result.stdout if result.returncode == 0 else ""


def repo_root(cwd: str) -> Path | None:
    if not cwd or not Path(cwd).is_dir():
        return None
    top = git(Path(cwd), "rev-parse", "--show-toplevel").strip()
    return Path(top).resolve() if top else None


def trusted(root: Path) -> bool:
    for entry in TRUSTED_ROOTS:
        base = Path(entry).expanduser().resolve()
        if root == base or base in root.parents:
            return True
    return False


def snapshot(root: Path) -> Snapshot:
    head = git(root, "rev-parse", "-q", "--verify", "HEAD").strip()
    tokens = git(root, "status", "--porcelain=v1", "-z", "--untracked-files=all").split("\0")
    files: dict[str, list[Any]] = {}
    index = 0
    while index < len(tokens):
        entry = tokens[index]
        index += 1
        if len(entry) < 4:
            continue
        status, path = entry[:2], entry[3:]
        if status[0] in "RC":
            index += 1  # The original path of a rename or copy follows.
        try:
            stat = (root / path).lstat()
            files[path] = [status, stat.st_size, stat.st_mtime_ns]
        except OSError:
            files[path] = [status, -1, -1]
    return {"head": head, "files": files}


def changed_paths(root: Path, before: Snapshot, after: Snapshot) -> list[str]:
    old, new = before.get("files", {}), after.get("files", {})
    paths = {path for path in old.keys() | new.keys() if old.get(path) != new.get(path)}
    if before.get("head") and after.get("head") and before["head"] != after["head"]:
        diff = git(root, "diff", "--name-only", "-z", before["head"], after["head"])
        paths.update(filter(None, diff.split("\0")))
    return sorted(paths)


def language_of(path: str) -> str | None:
    name = Path(path).name
    for language, (suffixes, names, _) in LANGUAGES.items():
        if name.endswith(suffixes) or name in names:
            return language
    if name.startswith("tsconfig") and name.endswith(".json"):
        return "js"
    return None


def nearest(root: Path, start: Path, names: tuple[str, ...]) -> Path | None:
    for directory in (start, *start.parents):
        if any((directory / name).exists() for name in names):
            return directory
        if directory == root:
            break
    return None


def js_checks(project: Path, root: Path, files: list[Path]) -> CheckPlan:
    if nearest(root, project, ("node_modules",)) is None:
        return "dependencies are not installed"
    try:
        scripts = json.loads((project / "package.json").read_text()).get("scripts") or {}
    except (OSError, ValueError, AttributeError):
        return "package.json is unreadable"
    lockfiles = (
        ("pnpm-lock.yaml", ["pnpm", "run", "--silent"]),
        ("yarn.lock", ["yarn", "run"]),
        ("bun.lock", ["bun", "run"]),
        ("bun.lockb", ["bun", "run"]),
    )
    runner = ["npm", "run", "--silent"]
    for lockfile, command in lockfiles:
        if nearest(root, project, (lockfile,)) is not None:
            runner = command
            break
    if shutil.which(runner[0]) is None:
        return f"{runner[0]} is not on PATH"
    selected = []
    for candidates in (TYPECHECK_SCRIPTS, LINT_SCRIPTS):
        for name in candidates:
            body = scripts.get(name)
            if isinstance(body, str) and not WRITING_SCRIPT.search(body):
                selected.append(name)
                break
    if not selected:
        return "no lint or typecheck script that leaves files unchanged"
    return [(f"{runner[0]} run {name}", [*runner, name]) for name in selected]


def python_checks(project: Path, root: Path, files: list[Path]) -> CheckPlan:
    sources = [f for f in files if f.suffix in (".py", ".pyi") and f.is_file()]
    if not sources:
        return "no Python files to check"
    pyproject = project / "pyproject.toml"
    configured = (project / "ruff.toml").exists() or (project / ".ruff.toml").exists() or (
        pyproject.exists() and "[tool.ruff" in pyproject.read_text(errors="replace")
    )
    if not configured:
        return "ruff is not configured"
    ruff = next(
        (str(p) for p in (project / ".venv/bin/ruff", root / ".venv/bin/ruff") if p.is_file()),
        shutil.which("ruff"),
    )
    if ruff is None:
        return "ruff is not installed"
    relative = [str(f.relative_to(project)) for f in sources]
    return [("ruff check", [ruff, "check", "--no-fix", "--quiet", *relative])]


def go_checks(project: Path, root: Path, files: list[Path]) -> CheckPlan:
    if shutil.which("go") is None:
        return "go is not on PATH"
    packages = sorted({
        "./" + str(f.parent.relative_to(project)) if f.parent != project else "."
        for f in files
        if f.suffix == ".go" and f.parent.is_dir()
    }) or ["./..."]
    return [("go vet", ["go", "vet", *packages])]


def rust_checks(project: Path, root: Path, files: list[Path]) -> CheckPlan:
    if shutil.which("cargo") is None:
        return "cargo is not on PATH"
    command = "clippy" if shutil.which("cargo-clippy") else "check"
    return [(f"cargo {command}", ["cargo", command, "--all-targets", "--quiet"])]


def dart_checks(project: Path, root: Path, files: list[Path]) -> CheckPlan:
    sources = [f for f in files if f.suffix == ".dart" and f.is_file()]
    if not sources:
        return "no Dart files to check"
    flutter = "sdk: flutter" in (project / "pubspec.yaml").read_text(errors="replace")
    prefix = ["fvm"] if nearest(root, project, (".fvmrc",)) and shutil.which("fvm") else []
    tool = "flutter" if flutter else "dart"
    if shutil.which(prefix[0] if prefix else tool) is None:
        return f"{tool} is not on PATH"
    if flutter:
        relative = [str(f.relative_to(project)) for f in sources]
        argv = [*prefix, "flutter", "analyze", "--no-pub", "--no-fatal-infos", *relative]
    else:
        # dart analyze accepts only a directory.
        argv = [*prefix, "dart", "analyze", "--no-fatal-infos", "."]
    return [(f"{tool} analyze", argv)]


BUILDERS: dict[str, Callable[[Path, Path, list[Path]], CheckPlan]] = {
    "js": js_checks,
    "python": python_checks,
    "go": go_checks,
    "rust": rust_checks,
    "dart": dart_checks,
}


def tail(output: str) -> str:
    lines = output.strip().splitlines()[-TAIL_LINES:]
    return "\n".join(lines)[-TAIL_CHARS:] or "(no output)"


def evaluate(root: Path, paths: list[str]) -> str | None:
    groups: dict[tuple[str, Path], list[Path]] = {}
    code_files = 0
    for path in paths:
        language = language_of(path)
        if language is None:
            continue
        code_files += 1
        absolute = root / path
        project = nearest(root, absolute.parent, LANGUAGES[language][2])
        if project is not None:
            groups.setdefault((language, project), []).append(absolute)

    started = time.monotonic()
    failures: list[str] = []
    passed: list[str] = []
    skipped: list[str] = []
    for (language, project), files in sorted(groups.items()):
        where = "." if project == root else str(project.relative_to(root))
        plan = BUILDERS[language](project, root, files)
        if isinstance(plan, str):
            skipped.append(f"{language} in `{where}` ({plan})")
            continue
        for label, argv in plan:
            if time.monotonic() - started > TOTAL_BUDGET:
                skipped.append(f"`{label}` in `{where}` (time budget spent)")
                continue
            try:
                result = subprocess.run(
                    argv,
                    cwd=project,
                    capture_output=True,
                    text=True,
                    errors="replace",
                    stdin=subprocess.DEVNULL,
                    timeout=CHECK_TIMEOUT,
                    env={**os.environ, "NO_COLOR": "1", "FORCE_COLOR": "0"},
                    check=False,
                )
            except subprocess.TimeoutExpired:
                skipped.append(f"`{label}` in `{where}` (timed out after {CHECK_TIMEOUT}s)")
                continue
            except OSError as error:
                skipped.append(f"`{label}` in `{where}` ({error.strerror})")
                continue
            if result.returncode == 0:
                passed.append(f"`{label}` in `{where}`")
            else:
                failures.append(
                    f"- `{' '.join(argv)}` in `{where}` exited {result.returncode}:\n"
                    f"```\n{tail(result.stdout + result.stderr)}\n```"
                )

    not_checked = f"\n\nNot checked: {'; '.join(skipped)}." if skipped else ""
    if failures:
        return (
            "Automated checks failed for files changed in this turn:\n\n"
            + "\n\n".join(failures)
            + f"\n\n{FIX_GUIDANCE}{not_checked}"
        )
    if code_files >= REVIEW_THRESHOLD:
        ran = ", ".join(passed) if passed else "none ran"
        return (
            f"This turn changed {code_files} code files. Checks passed: {ran}."
            f"{not_checked}\n\n{REVIEW_GUIDANCE}"
        )
    return None


def state_file(host: str, session: str) -> Path:
    safe = re.sub(r"[^A-Za-z0-9_.-]", "_", session)[:128]
    return Path.home() / ".cache" / "ai-standards" / "verify-turn" / f"{host}-{safe}.json"


def load_state(path: Path) -> dict[str, Snapshot]:
    try:
        value = json.loads(path.read_text())
    except (OSError, ValueError):
        return {}
    return value if isinstance(value, dict) else {}


def save_state(path: Path, state: dict[str, Snapshot]) -> None:
    path.parent.mkdir(mode=0o700, parents=True, exist_ok=True)
    with tempfile.NamedTemporaryFile("w", dir=path.parent, delete=False) as handle:
        json.dump(state, handle)
        temporary = Path(handle.name)
    os.replace(temporary, path)


def prune(directory: Path) -> None:
    cutoff = time.time() - STATE_TTL
    for path in directory.glob("*.json"):
        try:
            if path.stat().st_mtime < cutoff:
                path.unlink()
        except OSError:
            pass


def session_and_cwd(host: str, payload: dict[str, Any]) -> tuple[str, str]:
    session = payload.get("conversation_id") if host == "cursor" else None
    session = session or payload.get("session_id") or ""
    cwd = payload.get("cwd") or ""
    roots = payload.get("workspace_roots")
    if host == "cursor" and isinstance(roots, list) and roots and isinstance(roots[0], str):
        cwd = roots[0]
    return str(session), str(cwd or os.getcwd())


def start(host: str, payload: dict[str, Any]) -> None:
    session, cwd = session_and_cwd(host, payload)
    root = repo_root(cwd)
    if not session or root is None or not trusted(root):
        return
    path = state_file(host, session)
    state = load_state(path)
    # Resume and compaction also fire SessionStart; keep the existing baseline
    # so edits made earlier in the turn still count.
    if str(root) not in state:
        state[str(root)] = snapshot(root)
        save_state(path, state)
    prune(path.parent)


def stop(host: str, payload: dict[str, Any]) -> str | None:
    if host == "cursor":
        if payload.get("status", "completed") != "completed":
            return None
        continued = bool(payload.get("loop_count"))
    else:
        continued = bool(payload.get("stop_hook_active"))
    session, cwd = session_and_cwd(host, payload)
    root = repo_root(cwd)
    if not session or root is None or not trusted(root):
        return None
    path = state_file(host, session)
    state = load_state(path)
    before = state.get(str(root))
    current = snapshot(root)
    state[str(root)] = current
    save_state(path, state)
    if before is None or continued:
        return None
    paths = changed_paths(root, before, current)
    return evaluate(root, paths) if paths else None


def emit(host: str, event: str, message: str | None) -> None:
    if host == "cursor":
        print(json.dumps({"followup_message": message} if message else {}))
    elif event == "stop" and message:
        print(json.dumps({"decision": "block", "reason": message}))


def main() -> None:
    if len(sys.argv) != 3 or sys.argv[1] not in ("claude", "codex", "cursor") or sys.argv[2] not in ("start", "stop"):
        print("usage: verify-turn.py <claude|codex|cursor> <start|stop>", file=sys.stderr)
        raise SystemExit(0)
    host, event = sys.argv[1], sys.argv[2]
    message = None
    try:
        payload = json.loads(sys.stdin.read() or "{}")
        if isinstance(payload, dict):
            if event == "start":
                start(host, payload)
            else:
                message = stop(host, payload)
    except Exception as error:  # Fail open: a broken quality hook must not trap the agent.
        print(f"verify-turn: {error!r}", file=sys.stderr)
        message = None
    emit(host, event, message)


if __name__ == "__main__":
    main()
