---
name: mongo-aggregations
description: >-
  Write and change Mongoose aggregation pipelines the way this API already does.
  Use when adding or editing .aggregate(), $lookup, $match, $group, or
  list/dashboard queries. Use MongoDB connections only when Rudra explicitly
  authorizes the named MCP or supplied URL for the current task.
---

# Mongo aggregations

Inspect a neighbor in the same feature, then verify its stage order against
this query's semantics. Reuse conventions, not an unrelated query plan.

## MongoDB access

Do **not** access Homes data unless Rudra explicitly says `use <MCP name>` or `use <MongoDB URL>`.

Authorization applies only to the named connection and current task. A configured connection, URL in settings, or URL from an earlier task is not permission.

Read operations such as `find`, `aggregate`, `count`, `explain`, schema, and index inspection are allowed after authorization. Never perform writes, create or alter indexes, or call a mutating tool.

Never save, commit, log, repeat, or expose a supplied URL or its credentials. Pass it only to the authorized connection operation.

All Homes queries must be scoped by `project` unless the query's sole purpose is to identify duplicate groups across projects; in that case, group by `project` and return only project IDs, record IDs, and non-sensitive fields needed for remediation.

Plugin docs (`search-knowledge`) are always safe to read.

## Write the pipeline

1. Open the closest existing `.aggregate()` in that feature (payments, helpdesk, visitors, …). Match its stages and collection names.
2. Prefer `find` / `findOne` if that neighbor does not aggregate.
3. Push source-field filters early where legal. Some stages such as `$geoNear`
   must come first. Preserve tenant filtering, including foreign tenant-owned
   data, rather than assuming the outer `project` filter secures every join.
4. Page before `$lookup` only when it enriches an already selected page without
   changing eligibility, sort order, or row cardinality. If a filter or sort
   depends on joined data, apply it before pagination. Keep count and page
   semantics aligned and use a stable tie-breaker for ordering.
5. Join fields needed for filtering, sorting, authorization, or output. Inspect
   indexes for the actual join predicate; an index declaration is not evidence
   that it is deployed or used. Propose needed index changes via schema-design.
6. `$project` at the end to shape the response. Do not `$project` away fields before a `$match` that needs them.
7. Inspect `$unwind` expansion and repeated per-row queries for unbounded work.
   Validate missing joins, empty arrays, duplicates, and page boundaries with
   fixtures; do not trade correct results for a cheaper stage order.

## Slow?

Say it might be slow. Name the compound index you would want, from the `$match` + `$sort` keys. Run `explain` only after explicit MongoDB access authorization.

## Output before code

- Neighbor pipeline you copied (path)
- Stage order in one line
- Indexes already on disk that this uses, or the index you need to add
