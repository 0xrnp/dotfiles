---
name: golang-testing
description: Write Go tests that lock observable behavior and do not depend on order, shared state, or new test frameworks. Use when adding or changing Go tests. go-engineering and the repository win on conflict.
---

# Go testing

Use `testing` and the helpers the module already has. Do not add `gotests`, `testify`, or `goleak` to write a test.

## What the test proves

- Assert what the caller can see: return values, errors via `errors.Is` or `errors.As`, and side effects the function claims. An assertion on an unexported step fails on a refactor that preserves behavior.
- Several cases are a table with a name and `t.Run`. One case is a normal test function.
- Each test builds its own state. A later test must not rely on an earlier one having run.
- `t.Parallel` only when the test does not share mutable package state, files, ports, or environment. Do not add it as a style pass.
- A test that needs a database or the network uses the build tag the repository already uses. Do not invent a tag for one file.

## Files

A new test file is named after its source file (`foo.go`, `foo_test.go`). Leave existing test file names as they are.

## Concurrency

If the code under test starts goroutines, the test waits until they finish. Use `go.uber.org/goleak` only when it is already a dependency, and only in the pattern the module already uses. Race detection follows `go-engineering`.
