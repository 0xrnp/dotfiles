---
name: blast-radius
description: >-
  Map the callers, contracts, stored copies, integrations, and tests affected by
  changing existing behavior or shared code. Use before cross-cutting changes
  or when asked what else could break.
---

# Blast radius

Use for feature work and changes to existing behavior. Find connections from
repository evidence. Do not guess.

Greenfield stored shape is `schema-design`. Pipeline shape is `mongo-aggregations`.

## Trace

Start from the symbol, field, route, event, resource, or behavior being changed:

- Writers and mutation paths
- Readers and callers
- Serialized, cached, indexed, or denormalized copies
- Public APIs, DTOs, events, CLI output, configuration, and stored data
- Jobs, queues, retries, webhooks, scripts, infrastructure, and clients
- Tests, fixtures, migrations, compatibility paths, and rollout assumptions
- Security, tenancy, privacy, concurrency, performance, and failure boundaries

Search by symbol, field name, route, serialized key, event name, and semantic
equivalent. An empty map is credible only for genuinely isolated new code.

## Print before editing

| Thing | Direction | What breaks if this change is wrong |
|---|---|---|
| writers | | |
| readers | | |
| copies and stored state | | |
| contracts and clients | | |
| jobs and integrations | | |
| tests and operations | | |

For Homes, explicitly name SOS, payments, Razorpay, visitors, gates, CallKit,
Shorebird, and tenant `project` scope when present.

## Ask vs continue

Ask when ownership is unclear, a contract must break, data needs destructive
migration or backfill, a side effect can duplicate, or an unapproved high-risk
boundary is involved.

Continue to the plan when the repository answers the question, the change is
compatible, and the impact map is complete.

Do not invent questions to look careful. This skill maps product coupling.
Repository test-impact guidance decides which checks to run.
