---
name: self-review
description: Review the final diff for scope, correctness, contracts, unsafe assumptions, and missing evidence. Use before finishing non-trivial or multi-file changes.
disable-model-invocation: true
---

# Self-review

Read this before claiming done on non-trivial or multi-file work. Review the
actual diff, not the intended change.

## Scope and evidence

- Every changed line supports the approved outcome.
- No unrelated cleanup, formatting, dependency, file, field, flow, or generated
  artifact entered the diff.
- Unrelated user changes remain intact.
- APIs, commands, flags, paths, and framework patterns exist in the repository
  or current official documentation for the installed version.
- Report only checks and environments actually run.

## Correctness

- Re-read the request and success criteria against the result.
- Check failure paths, null or missing values, boundaries, concurrency, retries,
  ordering, cancellation, and partial side effects where relevant.
- Preserve public, persisted, error, and side-effect contracts unless an
  intentional change was approved.
- Validate untrusted input. Preserve authentication, authorization, tenant, and
  privacy boundaries.
- No silent catch, false success, or best-effort side effect blocking the main
  business operation.

## Design

- The implementation matches neighboring architecture.
- Every new abstraction has more value than direct code.
- Repeated syntax was not mistaken for repeated knowledge.
- Transport, domain, and persistence types are separated only when their
  semantics differ.
- Comments explain invariants or reasons, not syntax.

## Stack checks

Apply only the matching skill's checklist. In particular:

- Rust: ownership, panic, unsafe, async, feature, target, and MSRV implications.
- JS/TS: boundary types, runtime validation, async errors, and no unjustified
  `any` or assertion.
- Dart/Flutter: null safety, async lifecycle, state ownership, and generated
  files.
- Python: typed boundaries, async blocking, mutable defaults, resource cleanup,
  and repository tooling.
- Terraform: state movement, replacement risk, provider versions, secrets, and
  plan scope.

## Report

Report changed files, why the diff is minimal, verification commands and
results, skipped checks, and residual risks. State uncertainty plainly.
