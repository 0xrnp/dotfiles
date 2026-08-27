---
name: mongo-aggregations
description: >-
  Write and change Mongoose aggregation pipelines the way this API already does.
  Use when adding or editing .aggregate(), $lookup, $match, $group, or
  list/dashboard queries. Use MongoDB connections only when Rudra explicitly
  authorizes the named MCP or supplied URL for the current task.
---

# Mongo aggregations

Write pipelines like this API. Copy a **neighbor in the same feature**. Do not invent a new `$lookup` graph.

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
3. `$match` first. Non-public data: `project` in that `$match`.
4. `$sort` / `$skip` / `$limit` **before** `$lookup` when you are paging a list (see `payments.service.ts`).
5. `$lookup` only for fields the response actually needs. Foreign field must already be indexed in `src/models` (or you add that index in the same change, via `schema-design`).
6. `$project` at the end to shape the response. Do not `$project` away fields before a `$match` that needs them.
7. Unbounded `$unwind` of a huge array is a bug. So is `$lookup` inside a loop in JS.

## Slow?

Say it might be slow. Name the compound index you would want, from the `$match` + `$sort` keys. Run `explain` only after explicit MongoDB access authorization.

## Output before code

- Neighbor pipeline you copied (path)
- Stage order in one line
- Indexes already on disk that this uses, or the index you need to add
