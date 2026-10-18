---
name: golang-concurrency
description: Prevent Go goroutine leaks, channel ownership bugs, and unsynchronized shared state. Use when adding or changing goroutines, channels, mutexes, atomics, worker pools, or shutdown of concurrent work. go-engineering and the repository win on conflict.
---

# Go concurrency

`go-engineering` owns package shape, dependencies, and verification. This skill is the failure list. Do not add `errgroup`, `singleflight`, `goleak`, or any other module to satisfy it. Use what `go.mod` already requires. Otherwise use the standard library.

A synchronous call is the default. Concurrency needs an owner and a reason the synchronous call is wrong.

## Before starting a goroutine

The code has to answer all four:

- How it exits: context cancel, a closed channel, or a finished job.
- How the owner stops it.
- How the owner waits for it: `WaitGroup`, or the group type the package already uses.
- Who closes each channel. Only the sender closes. `WaitGroup.Add` runs before `go`, not inside the goroutine.

A goroutine with no exit path is a leak. Cancellation alone does not wait for it.

## select, timers, channels

- A `select` in work that can outlive the caller includes `ctx.Done()`.
- Do not call `time.After` in a loop. Use `time.NewTimer` and `Reset`, and stop the timer on the way out.
- Prefer an unbuffered channel. A buffer needs a known bound, not a guess that hides backpressure.
- Put a channel direction on a function that only sends or only receives.
- Send values. A pointer on a channel is shared memory and needs the same protection as a mutex.

## Shared state

- Use a mutex or atomics for shared memory. Use a channel when ownership of a value moves to the receiver.
- Do not hold a mutex across I/O, a channel operation, or another lock.
- Do not take an `RWMutex` write lock while holding its read lock.
- A concurrent map read and write crashes the process. Guard the map. `sync.Map` is for the read-heavy case the standard library documents, not a default.
- Bound how many goroutines can be in flight. An unbounded `go` per request leaks under load.

## Proof

A passing test does not show there is no race. When this behavior changes, `go-engineering` requires `go test -race` on the affected packages. Say so when the target cannot run the race detector.
