---
name: pr-review
description: >-
  Deep read-only review of someone else's Bitbucket pull request with file,
  line, severity, and fix guidance. Use for /pr-review, a Bitbucket PR URL or
  id, or when Rudra asks to review a colleague's PR without posting comments.
disable-model-invocation: true
---

# PR review (Bitbucket, read-only)

Use when Rudra runs `/pr-review`, names this skill, or asks to review someone
else's Bitbucket PR without posting comments. This skill does not authorize
posting comments, approving, merging, or changing the PR.

Load `~/.cursor/skills/bkt/SKILL.md` or use `bkt` CLI docs when flag details
matter. Repository instructions and Homes skills override generic review advice.

## Resolve the PR

Accept a numeric id, a Bitbucket URL, or `project/repo#id`.

Parse URLs:

- Data Center:
  `https://<host>/projects/<PROJECT>/repos/<REPO>/pull-requests/<ID>`
- Cloud:
  `https://bitbucket.org/<workspace>/<repo>/pull-requests/<ID>`

Run `bkt auth status` first. Use `--context`, `--project`, `--repo`, or
`--workspace` when the active context does not match the PR.

Record: host, project or workspace, repo slug, PR id, title, author, source and
target branches.

## Inspect

Fetch read-only PR context:

```bash
bkt pr view <id> --json
bkt pr diff <id>
bkt pr checks <id>
bkt pr comments <id> --details
```

For deep review (callers, contracts, stored shape, tests), check out the PR
branch in a dedicated worktree. Obey the checkout gate in
`~/ai-standards/AGENTS.md`. Homes repos use
`~/workspace/homes/worktrees/<repo>/pr-<id>/`. Other repos use
`~/workspace/worktrees/<repo>/pr-<id>/`. Use `bkt pr checkout <id>` inside
that clone. Checkout requires separate approval; diff-only review is acceptable
when checkout is blocked.

Load stack and domain skills from the repository:

- Homes Dart/Flutter: `homes-flutter`, `homes-git`
- Homes API/Angular/Node: `homes-js-ts`, `homes-git`
- Other Dart/Flutter: `dart-flutter-engineering`
- Other JS/TS: `js-ts-engineering`
- Python, Rust, Terraform: matching language skill
- Persisted or API contract changes: `schema-design`, `contract-design`
- Shared or cross-cutting behavior: `blast-radius`

Read repository instructions, PR description, linked tickets, and existing
review threads. Do not duplicate unresolved comments unless the code changed.

## Review

Apply `self-review` to the PR diff and any checked-out context. Prioritize:

1. Correctness, security, privacy, tenancy, and data integrity
2. Public, persisted, error, and side-effect contracts
3. Missing validation at trust boundaries
4. Concurrency, retries, ordering, and partial failure
5. Scope creep and unrelated changes
6. Tests and verification gaps (report `Not run` honestly)

For each finding assign:

- **ID**: `C1`, `C2`, ... (stable for later `/add-pr-comments`)
- **Severity**: `blocker`, `major`, `minor`, `nit`, or `question`
- **Location**: `path/to/file.ext:line` on the **new** side when possible
- **Line side**: `to` (added/changed in destination) or `from` (removed only)
- **Issue**: what is wrong and why it matters
- **Suggestion**: concrete fix or alternative

Derive line numbers from the unified diff hunk headers, not from memory. When
a comment must anchor on deleted lines only, use side `from`.

Split large PRs by directory or concern when context limits bite. Say when a
pass is partial.

## Report

Start with PR identity, branch pair, CI summary, and review scope (diff-only
vs checked out).

### Findings table

| ID | Severity | Location | Issue | Suggestion |
|---|---|---|---|---|
| C1 | major | `src/foo.ts:42` | ... | ... |

### Detailed notes

One subsection per finding (`#### C1 - path:line`) with evidence, blast radius,
and recommended fix. Apply `unslop` to comment text you expect Rudra may post
later.

End with:

- Findings count by severity
- Residual risks and unchecked areas
- Which finding IDs Rudra may want to post (`/add-pr-comments` or
  `/pr-review-and-comment`)

Do not post Bitbucket comments, approve, merge, or edit code unless Rudra asks
for a separate implement task.
