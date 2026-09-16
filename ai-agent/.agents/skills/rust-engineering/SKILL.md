---
name: rust-engineering
description: Implement, debug, and review Rust with repository-compatible ownership, error, async, unsafe, feature, target, and MSRV decisions. Use for .rs files, Cargo manifests, toolchains, or Rust failures.
---

# Rust engineering

Read repository instructions, neighboring code, tests, Cargo manifests,
toolchain pins, edition, `rust-version`, feature definitions, targets, and CI
before changing behavior.

## Constraints

- Distinguish the installed compiler from the minimum supported Rust version.
- Do not upgrade editions, toolchains, dependencies, features, or lockfiles as
  incidental cleanup.
- Confirm unfamiliar standard-library and crate APIs against the applicable
  version.
- Preserve public APIs, serialization, feature combinations, and supported
  targets.
- Check downstream implications of trait bounds, auto traits (`Send`/`Sync`),
  exhaustive matches, default features, and public dependency types. An additive
  API change is not automatically source compatible.

## Implementation

- Prefer the standard library, existing dependencies, and local patterns.
- Avoid new traits, macros, wrappers, modules, and generic parameters without a
  concrete caller or invariant.
- Understand ownership errors before adding clones, allocation, `Arc`, locks,
  or complex lifetimes. A small justified clone can be clearer than fragile
  borrowing.
- Preserve error types and propagation. Do not add panic, `unwrap`, or `expect`
  paths for recoverable input failures.
- Use safe Rust. Unsafe code requires documented safety invariants, validation
  of every caller, and focused tests.

## Async and concurrency

Inspect cancellation, lock ordering, lock lifetime, blocking work, task
ownership, boundedness, shutdown, and channel failure. Never hold a synchronous
lock across `.await` unless the repository proves it is safe and necessary.

Do not claim thread safety, ordering, idempotency, or performance from the type
system alone. Identify what the compiler proves and what still requires design
or testing.

Dropping a future may cancel it between side effects. Check what state and
resources remain, including spawned tasks that outlive their caller. Define
who joins or cancels each task and how failures reach that owner. Use RAII for
synchronous cleanup; do not assume `Drop` can perform asynchronous recovery.

## Performance and platforms

Support optimization claims with measurement or a known complexity, memory,
latency, hardware, or real-time constraint. Consider `no_std`, FFI, allocation,
and platform behavior only when the crate or change uses them.

## Verify

Use repository commands and the actual feature/target matrix. Start with the
affected crate and regression test, then broaden in proportion to shared or
public behavior. Appropriate checks may include formatting, check, Clippy,
tests, documentation tests, MSRV, and target builds.

Do not assume `--all-features` is valid. Features can be mutually exclusive.
Report exact commands, results, skipped matrices, and remaining risk.

Use property tests or fuzzing for parser/serialization invariants, Miri for
supported unsafe-code paths, and concurrency model checking when interleavings
justify it and the repository supports it. These are targeted tools, not a
mandatory suite or proof of soundness. Do not add dependencies without need.

## References when needed

- Compatibility: [Cargo SemVer guide](https://doc.rust-lang.org/cargo/reference/semver.html).
- Version support: [Cargo rust-version](https://doc.rust-lang.org/cargo/reference/rust-version.html).
- Unsafe invariants: [Rustonomicon](https://doc.rust-lang.org/nomicon/) and the applicable API's safety documentation.
- Async cancellation: the installed runtime and primitive's documentation.
