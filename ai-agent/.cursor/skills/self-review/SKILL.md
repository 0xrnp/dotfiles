---
name: self-review
description: Pre-done checklist against invented APIs, layer leaks, skipped verify, and silent failures. Use before claiming done on non-trivial or multi-file code changes.
disable-model-invocation: true
---

# Self-review

Read this before claiming done on non-trivial or multi-file work. Fix anything that fails. Do not skip a row because a skill "already said so".

## Hallucination (must be clean)

- Every API, package, CLI flag, and path exists in this repo **or** in current official docs for the **installed** version. If you did not read it this session, do not use it.
- If the file on disk disagrees with a skill, the **file** wins. Say so.
- No new dependency, field, flow, or folder shape Rudra did not ask for.
- Do not mix stacks (Flutter patterns in RN, BLoC in Angular, Angular services in the Node API).
- Do not claim a command, device, emulator, or prod run you did not execute.

## Always

- Smallest diff. Matches neighbors. No drive-by.
- Failures visible. No silent `catch` / fake success.
- Shared helpers keep their existing error contract.
- Best-effort side effects do not block the main write.
- Generated leftovers: none. No hand-edit of `*.g.dart`, `*.freezed.dart`, `*.config.dart`, RN codegen you did not run.

## By stack (only the one you touched)

**Flutter** — models stay out of widgets; `toEntity()` only in repos; `dart analyze` on touched files actually ran.

**API** — `project` tenant scope intact; no `any`; controllers still thin.

**Angular** — HTTP in existing services; no new store library.

**RN** — versions from `package.json`; docs for those versions; no Flutter architecture unless this RN repo already has it.

## Report

Changed files, why the diff is small, what you ran (or why not + exact manual steps), residual risks. If a hallucination check is uncertain, say uncertain — do not ship the guess.
