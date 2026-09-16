---
name: service-reliability
description: Design and change backend request, worker, queue, cache, and recovery behavior under load or partial failure. Use for retries, idempotency, concurrency limits, shutdown, service objectives, or incident diagnosis.
---

# Service reliability

Use for runtime and operational behavior, not every handler edit. Inspect the
actual request/job path, ownership, deployed limits, client contracts, tests,
and telemetry. Use system-design when choosing new service boundaries.

## Define the invariant

State what must remain true after a timeout, crash, retry, or concurrent request.
Trace each durable write and external effect. Establish what the caller sees
when the outcome is unknown, and how reconciliation determines the truth.

- Enforce deduplication atomically at the durable boundary. A read-then-write
  check or an expiring process lock alone does not make a payment idempotent.
- Scope idempotency keys to the correct tenant and operation. Define behavior
  for reuse with different input, concurrent attempts, and expired records.
- Database transactions do not roll back an external API call. Use existing
  provider idempotency, durable delivery, or reconciliation mechanisms. Introduce
  an outbox or compensating workflow only for a demonstrated atomicity gap.
- For queues, define acknowledgement timing, retry limits, poison-message
  handling, replay, ordering scope, and visibility/lease renewal. Do not claim
  exactly-once effects from an at-least-once transport.

## Bound work and failure

- Fit connection, query, and retry timeouts inside the caller's total budget.
  Retry only suitable failures and safe operations, with bounded attempts,
  backoff, and jitter. Avoid retries multiplying across layers.
- Bound concurrency, queues, request size, and connection pools. Specify what
  happens at capacity: reject, shed optional work, or wait within a deadline.
- Identify cancellation and shutdown owners. Stop accepting work, drain within
  a budget, and preserve unfinished durable work for another worker.
- Define cache ownership, expiry, invalidation, stampede control, stale-data
  tolerance, and recovery. Avoid using an evictable cache as the sole record
  preventing a financial duplicate.

## Operate and diagnose

Use existing telemetry. Choose signals tied to user outcomes: latency percentiles,
error rate, queue age, saturation, and failed effects. Keep label cardinality
bounded and exclude secrets and personal payloads. Trace IDs should connect
requests, jobs, and dependencies without logging sensitive content.

Base service objectives, capacity headroom, recovery time, and acceptable data
loss on actual requirements. During diagnosis, inspect timelines and recent
changes, distinguish cause from correlated symptoms, and propose the smallest
reversible mitigation. A diagnosis request does not authorize production writes.

## Verify

Exercise relevant failures using local fakes or an authorized test environment:
duplicate delivery, concurrent attempts, timeout after an effect, worker crash,
dependency outage, overload, and shutdown. Assert business invariants and
recovery behavior, not just status codes. Report what was actually reproduced.

Use official documentation for the installed queue, database, runtime, and
provider. Homes examples include BullMQ/Redis, SQS, Razorpay webhooks, and
Socket.IO; detect the repository instead of assuming one.
