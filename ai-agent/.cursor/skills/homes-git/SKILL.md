---
name: homes-git
description: Branching, worktrees, and Linear tickets for ASBL Homes git repos. Use when creating a branch, worktree, commit, PR, or when Rudra mentions a ticket ID.
disable-model-invocation: true
---

# Homes git

Personal skill. Do not create Linear tickets. Do not commit or push unless Rudra asked. Do not force-push main/master.

Homes git lives under `~/workspace/homes/**` (api, web, three Flutter apps, shared packages, lambdas).

## Ticket

- If Rudra gives an ID (`EREV-831`, `INS-10`, …), use it in the branch name.
- Before **branch / commit / PR** on a Homes repo: ask once for a ticket ID or `NO TICKET`. Wait if they skip.
- File edits in an already-approved plan may proceed without a ticket.
- Never create a Linear issue yourself. Linear MCP: only after it is authenticated; otherwise the ticket ID comes from chat.
- Comment/update Linear only when Rudra asks.

## Branch

1. `git fetch` (or pull) before you touch code on a new branch.
2. Default base: `main` / `master` unless that would collide with active `staging` / `test` work. If unsure, say so and ask. Check recent activity on those remotes; do not guess.
3. Name: `<ticket>-short-slug` when a ticket exists, otherwise the name Rudra gave.

## Worktrees

A worktree is a second checkout of the same repo so agent work does not smash a dirty main tree. You already use `~/workspace/homes/worktrees/<repo>/<name>/` (example: `homes-api-app/topaz-plover`).

**When to make one**

- Implementing (not answering a question).
- The main checkout is dirty, or two branches must exist at once.
- Prefer API / Angular. Flutter worktrees are expensive (`pub get`, `build_runner`, CocoaPods). Default Flutter: edit in place unless the tree is dirty or Rudra asks.

**When not**

- Nested worktree. Worktree into prod/staging checkouts. Worktree because a question was asked.
- Cursor isolated/best-of-n runs already create worktrees. Do not nest another inside those.

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
- PR body: short, `unslop` if you are writing more than a few lines.
