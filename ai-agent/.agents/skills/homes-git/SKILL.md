---
name: homes-git
description: Branching, worktrees, and Linear tickets for ASBL Homes git repos. Use when implementing in Homes, or when creating a branch, worktree, commit, PR, or when Rudra mentions a ticket ID.
---

# Homes git

Personal skill. Do not create Linear tickets. Do not commit or push unless Rudra asked. Do not force-push main/master.

Homes git lives under `~/workspace/homes/**` (api, web, three Flutter apps, shared packages, lambdas).

Use the checkout Rudra or the host supplied. The global checkout-placement rules
live in `~/ai-standards/AGENTS.md`. This skill adds Homes ticket, branch, and
worktree-path rules.

## Ticket

- If Rudra gives an ID (`EREV-831`, `INS-10`, …), use it in the branch name.
- Before **branch / commit / PR** on a Homes repo: ask once for a ticket ID. Wait if they skip.
- When there is no ticket, commits carry no marker. Never write `NO TICKET`.
- File edits within the requested scope may proceed without a ticket.
- Never create a Linear issue yourself. Linear MCP: only after it is authenticated; otherwise the ticket ID comes from chat.
- Comment/update Linear only when Rudra asks.

Ask for a ticket ID before creating a branch, commit, or PR. A user who says
there is no ticket may proceed without one; no control token is required.

## Branch

1. `git fetch` (or pull) before you touch code on a new branch.
2. Default base: `main` / `master` unless that would collide with active `staging` / `test` work. If unsure, say so and ask. Check recent activity on those remotes; do not guess.
3. Name: `<ticket>-short-slug` when a ticket exists, otherwise the name Rudra gave.

## Worktrees (Homes paths)

When Rudra asks for a new worktree on a Homes repo, use
`~/workspace/homes/worktrees/<repo>/<name>/` (example: `homes-api-app/topaz-plover`), not the generic `~/workspace/worktrees/...` path.

Flutter worktrees are expensive (`pub get`, `build_runner`, CocoaPods). Use the
open checkout unless Rudra or the host supplied a worktree, or isolation is
needed for concurrent work.

**When not**

- Nested worktree. Worktree into prod/staging checkouts. Worktree because a question was asked.
- Cursor isolated/best-of-n runs already create worktrees. Do not nest another inside those.
- Rudra asked to edit the main checkout.

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
