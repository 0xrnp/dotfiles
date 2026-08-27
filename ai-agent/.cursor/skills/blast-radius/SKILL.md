---
name: blast-radius
description: >-
  Map what else breaks when changing an existing feature or a shared entity
  other features use. Use when updating existing behavior, touching flats,
  residents, payments, visitors, or project-scoped data, or when the user asks
  what else is affected. Not for greenfield schema theory or aggregation
  authoring.
---

# Blast radius

For **feature work and changing what already exists**. Find connections. Do not guess.

Greenfield stored shape is `schema-design`. Pipeline shape is `mongo-aggregations`.

## Trace (Grep, not memory)

From the model or field you are about to change:

- Other models that store the id or a copy of the field
- Services, controllers (mobile **and** web), crons, lambdas, webhooks
- Clients if the field is on an API contract (Flutter, Angular)
- Indexes, unique constraints, tenant `project` filters

If this map is empty, you did not look. Look again.

## Print before editing

| Thing | Direction | What breaks if this change is wrong |
|---|---|---|
| writers | | |
| readers | | |
| copies / denorm | | |
| API clients | | |
| jobs / webhooks | | |

Name SOS, payments, gate, or tenant `project` if they are in the radius, even if the ticket did not.

## Ask vs continue

**Ask and wait** if: two owners for the same field; migrate is destructive or needs backfill; you cannot find who writes it; SOS / payments / gate / tenant is in the radius and Rudra did not name it.

**Do not stall** if: a neighbor in the same feature already shows the pattern; the change is additive and compatible; the table is filled in. Plan-first still gates edits.

Do not invent a question to look careful. If the repo answered it, proceed.

Project `test-impact-analysis` is which **tests** to run. This skill is what else in the **product** is coupled.
