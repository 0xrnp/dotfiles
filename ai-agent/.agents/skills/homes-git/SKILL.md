---
name: homes-git
description: Branching, worktrees, and Linear tickets for ASBL Homes git repos. Use when implementing in Homes, or when creating a branch, worktree, commit, PR, or when Rudra mentions a ticket ID.
disable-model-invocation: true
---

# Homes git

Personal skill. Do not create Linear tickets. Do not commit or push unless Rudra asked. Do not force-push main/master.

Homes git lives under `~/workspace/homes/**` (api, web, three Flutter apps, shared packages, lambdas).

The global **Checkout gate** (`WORKTREE` / `MAIN`) lives in `~/ai-standards/AGENTS.md`. Obey that for every implement task. This skill only adds Homes ticket rules and the Homes worktree path when `WORKTREE` is chosen.

## Ticket

- If Rudra gives an ID (`EREV-831`, `INS-10`, …), use it in the branch name.
- Before **branch / commit / PR** on a Homes repo: ask once for a ticket ID or `NO TICKET`. Wait if they skip.
- A ticket id or `NO TICKET` may share the same message as checkout and plan
  tokens (one token per line; plan phrase last). Honor it in that stack.
- File edits in an already-approved plan may proceed without a ticket.
- Never create a Linear issue yourself. Linear MCP: only after it is authenticated; otherwise the ticket ID comes from chat.
- Comment/update Linear only when Rudra asks.

For a new Homes implement task you typically need both the global checkout answer (`WORKTREE` or `MAIN`) and a ticket answer (ID or `NO TICKET`) before mutating, unless an AGENTS.md checkout skip condition already applies.

## Branch

1. `git fetch` (or pull) before you touch code on a new branch.
2. Default base: `main` / `master` unless that would collide with active `staging` / `test` work. If unsure, say so and ask. Check recent activity on those remotes; do not guess.
3. Name: `<ticket>-short-slug` when a ticket exists, otherwise the name Rudra gave.

## Worktrees (Homes paths)

When Rudra answered `WORKTREE` on a Homes repo, use
`~/workspace/homes/worktrees/<repo>/<name>/` (example: `homes-api-app/topaz-plover`), not the generic `~/workspace/worktrees/...` path.

Prefer API / Angular for `WORKTREE`. Flutter worktrees are expensive (`pub get`, `build_runner`, CocoaPods); still obey the AGENTS.md gate, and prefer `MAIN` for Flutter unless the tree is dirty or Rudra chooses `WORKTREE`.

**When not**

- Nested worktree. Worktree into prod/staging checkouts. Worktree because a question was asked.
- Cursor isolated/best-of-n runs already create worktrees. Do not nest another inside those.
- Rudra answered `MAIN`.

**How**

```bash
git fetch
git worktree add -b <branch> ~/workspace/homes/worktrees/<repo>/<name> origin/main
```

Use the repo's real default branch instead of `main` if it is `master`. After add: install deps in that worktree. For Flutter, say that `pub get` / codegen will run before you do it.

Report the worktree path. Do all implementation in that path, not the dirty main checkout.

## Blast radius (git)

Name it before touching: production, live DB, Shorebird prod, daily-driver preview channels, Razorpay, SOS, CallKit, visitor gate, tenant `project` filters.

## PR / commit

- Ask first.
- No `Co-authored-by: Cursor` / `@cursor.com` trailers.
- Apply `commit-authoring` for commit messages and `pr-authoring` for PR titles
  and bodies.
