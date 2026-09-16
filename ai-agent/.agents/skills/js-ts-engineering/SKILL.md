---
name: js-ts-engineering
description: Implement and review JavaScript or TypeScript using repository versions, types, runtime boundaries, and existing framework patterns. Use for Node, browser, Angular, React, Astro, or library code; combine with homes-js-ts in Homes repositories.
---

# JavaScript and TypeScript engineering

Read `package.json`, lockfile, `tsconfig`, lint configuration, framework
configuration, and neighboring code before choosing an API or pattern.

Respect package `type`, ESM/CJS, `exports`, and TypeScript `module` /
`moduleResolution` settings. Match the actual runtime and build path: Node,
browser, and edge environments do not expose the same APIs. Do not invent import
styles, dual-package outputs, or runtime capabilities absent from repo evidence.

## Types and boundaries

- Prefer inference inside trusted code and explicit types at public boundaries.
- Use `unknown` for untrusted values, then validate or narrow it.
- Do not weaken compiler checks or add `any`, broad assertions, non-null
  assertions, casts, or suppression comments merely to silence errors. Preserve
  configured strictness, including `exactOptionalPropertyTypes` and
  `noUncheckedIndexedAccess` when enabled.
- Reuse existing types. Separate request, domain, and persistence types only
  when their semantics differ.
- Model variants with discriminated unions or the repository's equivalent when
  that removes invalid states.
- Runtime validation belongs where external data enters. Use the validator
  already installed.
- Preserve missing, `undefined`, `null`, and empty-value semantics at boundaries.
  Use `??` when only nullish values should trigger a fallback; retain valid `0`,
  `false`, and `""`. Do not replace intentional falsy checks mechanically.

## Behavior

- Preserve promise rejection, callback, event, status, error-body, and logging
  contracts, including error types and `cause` where used.
- Await work that must finish. Deliberately detach only best-effort work with
  visible failure handling.
- Consider cancellation, duplicate requests, races, resource cleanup, and
  process shutdown where relevant. Propagate supported abort signals and follow
  the API's cancellation contract. Distinguish caller cancellation from failure
  or timeout; do not swallow errors solely because their name is `AbortError`.
- Use repository utilities for dates, time zones, money, IDs, pagination, and
  serialization. Do not invent parallel helpers.
- Keep framework concerns in their existing layer. Do not move server patterns
  into browser code or one frontend framework's patterns into another.

## Dependencies and documentation

Use built-in APIs and installed dependencies first. Confirm unfamiliar or
version-sensitive APIs in current official documentation for the installed
version. Do not upgrade packages or tooling incidentally.

## Verify

Run the repository's narrowest relevant type check, lint, test, and build.
Broaden checks for shared types, public contracts, configuration, or generated
artifacts. Report exactly what ran.
