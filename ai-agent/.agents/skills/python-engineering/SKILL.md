---
name: python-engineering
description: Implement and review Python using the repository's supported version, typing, async, framework, packaging, and test conventions. Use for Python services, scripts, FastAPI, Pydantic, and data tooling.
---

# Python engineering

Read `pyproject.toml`, dependency files, lockfiles, supported Python version,
type checker, linter, formatter, test configuration, and neighboring modules.
Do not migrate tools merely because a newer tool exists.

## Types and data

- Type public boundaries and non-obvious return values using repository
  conventions.
- Avoid `Any` at trust boundaries. Parse external input into validated models or
  narrow structures.
- Preserve the distinction between missing, `None`, empty, and default values.
- Do not use mutable default arguments or shared mutable state accidentally.
- Prefer dataclasses, Pydantic models, protocols, or plain classes only where
  the existing architecture and semantics call for them.

## Runtime behavior

- Preserve exception types, status mapping, cleanup, logging, and retry
  behavior.
- In async code, do not run blocking I/O or CPU-heavy work on the event loop.
- Bound concurrency and queues when load can grow.
- Use context managers for files, connections, locks, and temporary resources.
- Consider cancellation and partial failure for background tasks.
- Keep framework handlers thin only when the repository already separates
  business behavior.

## Dependencies and documentation

Use the standard library and installed packages first. Confirm
version-sensitive framework APIs in official documentation for the installed
version. Do not replace pip, requirements files, mypy, Ruff, pytest, or project
layout unless requested.

## Verify

Use the repository's focused pytest command, type checker, linter, and formatter.
Broaden checks for shared models, async infrastructure, public contracts, or
packaging changes. Report skipped checks and why.
