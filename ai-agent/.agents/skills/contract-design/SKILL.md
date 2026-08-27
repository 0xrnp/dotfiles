---
name: contract-design
description: Design and change API, DTO, event, CLI, configuration, and public type contracts. Use when data crosses a module, process, service, client, or trust boundary.
---

# Contract design

Use this skill for observable boundaries. Do not create DTOs or interfaces
between internal functions that already share the same semantics.

## Establish the contract

1. Identify every producer and consumer from repository evidence.
2. Write the current input, output, error, nullability, ordering, and side-effect
   behavior.
3. Separate promised behavior from implementation details and accidental
   behavior consumers may still depend on.
4. Define trust boundaries and runtime validation for external input.

## Shape

- Reuse an existing type when transport, domain, and persistence mean the same
  thing.
- Separate them when fields, nullability, lifecycle, trust, or ownership differ.
- Model variants explicitly. Prefer exhaustive unions or enums over interacting
  booleans.
- Make missing, null, empty, default, omitted, and unknown-field behavior clear.
- Preserve the repository's error shape and status semantics.
- Expose the smallest stable surface. Do not leak storage or framework details.

## Compatibility

Prefer additive changes. Before removing, renaming, retyping, reordering, or
changing defaults, trace old clients, stored payloads, fixtures, jobs, and
mixed-version deployments.

For state-changing operations, consider duplicate delivery, timeout with unknown
outcome, idempotency, concurrent requests, and partial failure. Use the
repository's existing mechanism. Do not claim exactly-once behavior without an
atomic guarantee.

## Before code

Report:

- Producers and consumers
- Current and proposed contract
- Compatibility and migration behavior
- Validation and error semantics
- Retry and idempotency decision when relevant
- One rejected alternative and why it is worse

If the contract must break or ownership is unclear, ask before implementation.
