---
name: schema-design
description: >-
  Design durable SQL, document, cache, and event storage from access patterns
  and invariants. Use before changing collections, tables, fields, indexes,
  relations, migrations, retention, or ownership.
---

# Schema design

Stored shape outlives the implementation. Do this before proposing a field,
collection, table, index, event, cache key, or migration.

This is not blast-radius (who else breaks) and not aggregations (how we query). Those are other skills.

## Before a shape

1. Job: questions the data must answer, writers, readers, frequency, and growth.
2. Existing ownership: reuse a current source of truth rather than creating a
   competing copy.
3. Invariants: uniqueness, required relationships, ordering, money/precision,
   state transitions, and what must be atomic.
4. Horizon:
   - Cardinality and maximum expected size
   - Retention, archive, deletion, legal, and TTL requirements
   - Tenant, authorization, privacy, and encryption boundaries
   - Old data, old clients, mixed-version deploys, and rollback
   - Write contention, retries, idempotency, and partial failure
   - What this change intentionally does not solve
5. Queries: exact filters, joins/lookups, sorting, pagination, and update paths
   that justify the shape and indexes.

## SQL vs document

Choose from invariants and access patterns, not habit.

**SQL:** use relational constraints for invariants that span rows and data
queried in several directions. Normalize by default. Denormalize only for a
named query and define how the copy stays correct. Index real filter, join, and
sort paths.

**Document:** treat the document as the atomic unit. Embed bounded data owned and
fetched with its parent. Reference shared, independently updated, or unbounded
data. Avoid table-per-entity translation and unbounded arrays.

**Events and caches:** define the durable source of truth, key identity,
ordering, deduplication, expiration, replay, invalidation, and recovery after a
partial write. A cache is not the only copy of business data.

## Homes API

In Homes API, models live in `src/models/`. Neighbor models are the spec.
Preserve `project` on every non-public read and write. Do not add a collection
for data that belongs on an existing document.

## Output before code

- Proposed shape
- Ownership and invariants
- Named reads and writes it supports
- Why the closest alternative is worse
- Compatibility, migration, rollback, and old-client behavior
- Indexes justified by query shape already on disk
- Retention and operational risks

Ask when two shapes remain plausible, ownership is unclear, consistency changes,
or migration is destructive. Do not invent a question when the repository
already answers it.
