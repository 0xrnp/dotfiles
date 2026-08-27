---
name: mongo-aggregations
description: >-
  Write and change Mongoose aggregation pipelines the way this API already does.
  Use when adding or editing .aggregate(), $lookup, $match, $group, or
  list/dashboard queries. Do not use MongoDB MCP against Homes data unless Rudra
  pastes a readonly URL this session.
---

# Mongo aggregations

Write pipelines like this API. Copy a **neighbor in the same feature**. Do not invent a new `$lookup` graph.

## Do not touch the live DB

Do **not** call MongoDB MCP `connect`, `explain`, `find`, `aggregate`, or anything else against Homes data.

No connection string in chat, settings, or memory counts as permission. The only exception: Rudra pastes a **readonly** URL **in this session** and says to use it. Until then, reason from `src/models` and existing services.

Plugin docs (`search-knowledge`) are fine. Live cluster is not.

## Write the pipeline

1. Open the closest existing `.aggregate()` in that feature (payments, helpdesk, visitors, …). Match its stages and collection names.
2. Prefer `find` / `findOne` if that neighbor does not aggregate.
3. `$match` first. Non-public data: `project` in that `$match`.
4. `$sort` / `$skip` / `$limit` **before** `$lookup` when you are paging a list (see `payments.service.ts`).
5. `$lookup` only for fields the response actually needs. Foreign field must already be indexed in `src/models` (or you add that index in the same change, via `schema-design`).
6. `$project` at the end to shape the response. Do not `$project` away fields before a `$match` that needs them.
7. Unbounded `$unwind` of a huge array is a bug. So is `$lookup` inside a loop in JS.

## Slow?

Say it might be slow. Name the compound index you would want, from the `$match` + `$sort` keys. Do **not** run `explain`. If Rudra later gives a readonly URL, then MCP `explain` is allowed for that session only.

## Output before code

- Neighbor pipeline you copied (path)
- Stage order in one line
- Indexes already on disk that this uses, or the index you need to add
