---
name: go-engineering
description: Implement, debug, and review Go using repository toolchains, package contracts, error semantics, concurrency lifecycles, and tests. Use for .go files, go.mod, go.work, or Go failures.
---

# Go engineering

Read repository instructions, neighboring packages, tests, `go.mod`, `go.work`,
build tags, generated code, and CI before changing code. Distinguish the `go`
minimum version, suggested `toolchain`, and installed compiler. Preserve the
supported OS, architecture, CGO, and dependency constraints.

## Packages and contracts

- Prefer the standard library and existing packages. Keep related behavior in
  cohesive packages; do not impose a service/repository/interface tree.
- Define small interfaces at the consumer when substitution is needed. Return
  concrete types when callers do not need an abstraction. Use generics only
  when a shared algorithm or constraint warrants them.
- Make zero-value behavior, pointer/value semantics, mutation, and ownership
  explicit. Do not copy values containing a used mutex or other no-copy state.
- Preserve error identity and wrapping contracts. Use `errors.Is`/`errors.As`
  where appropriate; distinguish retryable failures from invalid input.
  Avoid panic for recoverable failures and typed-nil errors hidden in interfaces.

## Concurrency and resources

- Every goroutine needs an owner, a termination condition, and a way for its
  errors to reach that owner. Bound active work and queued work separately.
- Propagate the caller's context and deadlines. Cancel derived contexts when
  finished; cancellation alone does not wait for workers to stop.
- Identify who closes each channel. Sends and receives that may outlive their
  peer need cancellation or another proved completion path.
- Use mutexes for shared state when clearer than channels. Do not infer race
  freedom, transaction atomicity, or safe publication from passing tests.
- Close response bodies, files, rows, and transactions on every path. Check
  iteration errors. Use the transaction handle consistently within a transaction.
- For servers and clients, inspect timeout budgets, request/body limits,
  connection reuse, connection pools, and graceful shutdown. Do not start
  detached request work without an explicit durable owner.

## Verify

Use repository commands, starting with affected packages. Relevant checks are
`gofmt`, `go vet`, focused `go test`, and `go test -race` on supported targets
when concurrent behavior changes. The race detector covers executed paths only.
Use table tests for meaningful cases, fuzzing for input invariants, and benchmarks
with allocation reporting or profiles for measured performance work.

Do not run `go get`, change toolchains, or tidy unrelated modules as cleanup.
Inspect `go.mod`/`go.sum` changes produced by authorized tooling. Report exact
checks, skipped platform/build-tag combinations, and remaining uncertainty.

## References when needed

- Version and dependency decisions: [module reference](https://go.dev/doc/modules/gomod-ref).
- Unfamiliar APIs: installed `go doc`, then [standard library docs](https://pkg.go.dev/std) for that version.
- Performance work: [diagnostics](https://go.dev/doc/diagnostics).
- Concurrency validation: [race detector](https://go.dev/doc/articles/race_detector).
- Untrusted parsers: [fuzzing](https://go.dev/doc/security/fuzz/).

Effective Go is useful for idioms, but is not a complete guide to modern modules,
generics, or toolchain behavior. Do not copy another language's architecture.
