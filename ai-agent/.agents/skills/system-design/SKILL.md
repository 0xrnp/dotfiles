---
name: system-design
description: Evaluate architecture for new subsystems, cross-service flows, reliability, scale, concurrency, or operationally expensive decisions. Do not use for routine local edits.
---

# System design

Use this skill only when a decision crosses durable boundaries or has meaningful
operational consequences. A small feature inside an established pattern does
not need a system-design exercise.

## Start with evidence

1. State the user outcome and measurable success criteria.
2. Inspect the current topology, ownership, contracts, stored data, deployment,
   observability, and closest working flow.
3. Establish real constraints: traffic, data size, latency, availability,
   consistency, privacy, cost, team ownership, and supported platforms.
4. Mark unknown constraints. Do not invent scale.

Estimate capacity with units and stated assumptions when it changes the design:
peak arrival rate, service time, concurrency, storage growth, and cost. Use
measurements or a small experiment to test the limiting assumption. Compare
complexity and operability with the closest simpler design.

## Design the failure path

For each boundary, consider:

- Source of truth and ownership
- Authentication, authorization, tenancy, and trust
- Timeout, retry, cancellation, duplicate delivery, and backpressure
- Concurrency, ordering, idempotency, and partial failure
- Capacity limits and degradation behavior
- Observability needed to distinguish healthy, delayed, and failed work
- Deployment, compatibility, migration, rollback, and recovery

Prefer an existing component and direct flow. Add a service, queue, cache,
database, abstraction, or protocol only when a named constraint requires it.

## Decision

Present:

- Constraints and assumptions
- Current flow and proposed change
- Data and contract ownership
- Failure and recovery behavior
- Operational and security impact
- Smallest viable design
- Strongest credible alternative and why it loses
- Validation plan

Do not use pattern names as justification. Explain the concrete coupling,
failure mode, or constraint the choice addresses.
