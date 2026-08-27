---
name: schema-design
description: >-
  Think through SQL and NoSQL stored shape before adding or changing collections,
  tables, fields, indexes, or migrations. Use when designing models, embed vs
  reference, schema evolution, or a change that is expensive to undo. Not for
  feature blast-radius maps or aggregation pipelines.
---

# Schema design

Think past this ticket. Stored shape outlives the PR. Do this **before** proposing a field, collection, table, or index.

This is not blast-radius (who else breaks) and not aggregations (how we query). Those are other skills.

## Before a shape

1. **Job.** What questions must this data answer. Who writes, who reads, how often, how it grows.
2. **Search the repo.** Reuse an existing field, collection, or table. Do not invent a twin.
3. **Horizon** (answer even if briefly):
   - Cardinality: 1:1 / 1:few / 1:unbounded
   - Time: grows forever? archive or TTL?
   - Tenancy: every non-public row/doc scoped?
   - Old documents and old app versions
   - What this change is **not** solving

## SQL vs document

Pick from access patterns, not habit.

**SQL:** invariants that span rows, queried both ways, reporting. Normalize unless a **named** query needs a denorm. FK plus index on filter/join columns. Do not store JSON "just in case".

**Document (Mongo here):** the document is the unit of work. Embed 1:few that is always fetched together. Reference when the set is unbounded, or shared and updated on its own. Do not copy a SQL table-per-entity into collections. Unbounded arrays are a bug. Indexes exist only for real queries (see `src/models` for what this repo already indexes).

## Homes API

Models live in `src/models/`. Neighbor models are the spec. `project` on every non-public read and write. Do not add a collection for data that already belongs on an existing document.

## Output before code

- Proposed shape
- Why not the alternative, one line
- Compatibility: old docs, old clients
- Indexes you will or will not add, from query shape on disk, not from a live `explain`

If two shapes are both plausible, or the migrate is destructive, **ask**. Do not invent a question if the repo already answered.
