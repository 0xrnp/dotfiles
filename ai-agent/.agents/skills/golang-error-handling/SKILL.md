---
name: golang-error-handling
description: Keep Go error identity, wrapping, and logging from hiding or double-reporting failures. Use when creating, wrapping, checking, or logging Go errors. go-engineering and the repository win on conflict.
---

# Go error handling

Match the sentinels, wrappers, and logger already in the package. Do not add an error library. Do not switch the package to `slog` unless it already uses `slog`.

## Check and wrap

- Handle every returned error. `_` is acceptable only for a cleanup call whose failure the surrounding code already records, the way that file already does it.
- Wrap with `fmt.Errorf("doing x: %w", err)` when callers use `errors.Is` or `errors.As`. Use `%v` at a boundary that must not expose the internal chain, such as an HTTP body or a message sent to another system.
- Compare with `errors.Is` and `errors.As`. `==` misses a wrapped sentinel. A typed nil stored in an `error` interface is not a nil error.
- `errors.Join` only when the module's Go version is 1.20 or newer and the failures are independent.
- Error strings stay lowercase and have no trailing punctuation, matching the errors already in the file.
- `panic` is for a broken program invariant. A bad request, a timeout, or a missing record is a returned error.

## Log once

Log the error or return it. Doing both duplicates the report, unless this package's boundary is the only place that logs and callees only return. Follow that existing split. Do not invent a second logger at the call site.

Do not put tokens, request bodies, or raw user content into the error string. Identifiers operations already record belong in the structured fields the logger already has.

## Identity

Keep sentinel text stable. Callers match it with `errors.Is`. Distinguish retryable failures from invalid input the way the package already does.
