---
name: ts-correctness
description: Stop TypeScript changes from hiding broken data, dropped work, or overwritten invariants. Use when editing TypeScript or JavaScript behavior, types, async work, caught errors, validation, or object merges. js-ts-engineering and the repository win on conflict. In Homes, homes-js-ts also wins.
---

# TypeScript correctness

`js-ts-engineering` owns runtime, modules, and dependencies. This skill is the failure list. Match the file. Do not add a validation library, a result type, or a lint rule to satisfy it.

## The compiler is looser than the bug

Some repos set `"strict": true` and then turn off `strictNullChecks`, `noImplicitAny`, and `useUnknownInCatchVariables`. Homes API does this. Do not flip those flags unless the task asks for it. Write the touched code as if they were on:

- No new `any`. No `!`. No `as SomeType` on a value that came from JSON, a query string, `req.body`, a header, or a database.
- A `catch` variable is untrusted even when this `tsconfig` types it as `any`. Narrow it before reading a property.
- A green `tsc` run with those flags off does not prove a null or missing-field path. Name that path when you could not exercise it.

## Values that lie

- `||` treats `0`, `""`, and `false` as missing. Use `??` when those are real values. Keep an intentional falsy check when the existing condition means "absent or empty".
- Optional chaining on a required value (`user?.id`, then carry on) hides a missing record. Branch when the caller has to know it was missing.
- Later spreads overwrite earlier keys. Put the trusted fields last: tenant, owner, price, role. A client object spread after `project` deletes the tenant scope.
- `null`, `undefined`, and a missing key are different. Compare the sentinel the API already uses. Do not collapse them with a truthiness check unless the file already does that for the same field.

## Async

- Return or await the promise. A floating promise in a handler lets the response finish, then fails as an unhandled rejection.
- `void somePromise` only for work the file already treats as best-effort, and only if that rejection is logged.
- A `catch` that returns success, an empty object, or a default record reports a failure as data. Return the existing error shape.
- `Promise.all` abandons the other items on the first rejection. Do not use it for independent writes that must not be half-applied. Use the sequencing the service already uses for that kind of write.

## Types that erase a bug

- External data stays `unknown`, or the boundary type the repo already parses into, until something checks the fields you branch on. A type assertion does not check them.
- A Mongoose document, a lean object, and the API response are different shapes. Convert at the boundary the repo already uses. Do not pass the document through as the response type.
- `ObjectId` and `string` are not the same value. Compare them with the conversion already in the file.
- A boolean pair that can be set in an impossible combination (`isAdmin` together with a non-admin `role`) should be the discriminated union the file uses for its other states. Do not introduce a union style the file does not have.
- Do not widen a public function's parameters to `any`, `object`, or `Record<string, any>` so more callers compile. Name the fields that function reads.
- Do not add a function whose only job is a cast.

## Mutation

Do not mutate `req.body`, an argument, or an array the caller still uses. Copy when the shape has to change. An in-place delete or overwrite changes every later reader of that object, including middleware that already captured it.

## RxJS

When the file already uses Angular or RxJS, match its teardown (`async` pipe, `takeUntil`, or `unsubscribe` in `ngOnDestroy`). Do not add a second style. Do not nest `subscribe`.
