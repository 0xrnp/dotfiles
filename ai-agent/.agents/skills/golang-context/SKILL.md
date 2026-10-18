---
name: golang-context
description: Keep Go context.Context cancellation, deadlines, and values attached to the work that owns them. Use when adding, storing, or replacing a context, timeout, or cancel function. go-engineering and the repository win on conflict.
---

# Go context

## Propagation

- `ctx context.Context` is the first parameter. Do not store a context on a struct. The struct outlives the request, so the stored context is already cancelled or belongs to another caller.
- Pass the caller's context through the call chain. `context.Background()` in the middle of a request drops the client's cancel and deadline. `Background` belongs in `main`, `init`, and tests.
- `context.TODO()` marks a context the caller does not have yet. Do not pass a nil context. The first `Done` or `Value` call panics far from that nil.
- `defer cancel()` for every `WithCancel`, `WithTimeout`, and `WithDeadline`. A missed `cancel` keeps the child and its timer alive until the parent finishes.
- Cancel does not wait for workers. The owner still waits until they return. That wait is `golang-concurrency`.

## Values and lifetime

- A context value is request metadata the package already carries, under an unexported key type. A string key collides with another package. Function arguments stay arguments. `Value` erases their type.
- Work that must outlive the request uses `context.WithoutCancel` only when the module's Go version is 1.21 or newer, then applies its own deadline. Name who owns that work. `Background` is not a way around cancellation.
- Servers take `r.Context()`. Clients and database calls use the `Context` method the package already uses. Do not add a client whose only new feature is a context parameter.
