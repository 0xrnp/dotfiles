---
name: js-ts-engineering
description: Implement and review JavaScript or TypeScript using repository versions, types, runtime boundaries, and existing framework patterns. Use for Node, browser, Angular, React, Astro, or library code outside Homes.
---

# JavaScript and TypeScript engineering

Read `package.json`, lockfile, `tsconfig`, lint configuration, framework
configuration, and neighboring code before choosing an API or pattern.

## Types and boundaries

- Prefer inference inside trusted code and explicit types at public boundaries.
- Use `unknown` for untrusted values, then validate or narrow it.
- Do not add `any`, broad assertions, non-null assertions, or casts merely to
  silence the compiler.
- Reuse existing types. Separate request, domain, and persistence types only
  when their semantics differ.
- Model variants with discriminated unions or the repository's equivalent when
  that removes invalid states.
- Runtime validation belongs where external data enters. Use the validator
  already installed.

## Behavior

- Preserve promise rejection, callback, event, status, error-body, and logging
  contracts.
- Await work that must finish. Deliberately detach only best-effort work with
  visible failure handling.
- Consider cancellation, duplicate requests, races, resource cleanup, and
  process shutdown where relevant.
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
