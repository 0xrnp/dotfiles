---
name: add-pr-comments
description: >-
  Post finalized inline comments on a Bitbucket pull request after an earlier
  pr-review discussion. Use for /add-pr-comments or when Rudra asks to post
  only the agreed review comments.
---

# Add PR comments (Bitbucket)

Use when Rudra runs `/add-pr-comments` after discussing findings from
`/pr-review`, or when Rudra gives an explicit finalized comment list for a
Bitbucket PR. This skill posts comments only. It does not re-run a full review
unless Rudra asks to refresh findings first.

## Gather finalized comments

Prefer comments agreed in the current chat:

- Include only finding IDs Rudra kept (for example "post C1 and C3, skip C2").
- Apply rewrites Rudra requested before posting.
- If Rudra pastes a fresh list, treat that as authoritative over earlier IDs.

Each comment needs: PR ref (or reuse the PR from the same chat), file path,
line, side (`to` or `from`), and exact markdown body.

If the PR ref or any comment body is ambiguous, stop and ask once.

Optionally re-fetch `bkt pr diff` and `bkt pr view` to confirm line anchors
still match the current head. When a hunk moved, adjust the line from the
current diff and say so in the preview.

## Comment preview gate

Before any `bkt pr comment` command, show:

1. PR host, project or workspace, repo, id, and title.
2. Count of inline comments to post.
3. A numbered list with finding ID (when present), file, line, side, and the
   **exact** body for each comment.
4. End with:
   `Waiting to post N inline comment(s) on <project-or-workspace>/<repo> PR #<id>.`

Stop for separate explicit authorization. After this preview is pending, a
clear user request to post authorizes that preview only. No control token is
required.
Any change to the list or PR head requires a new preview.

## Execute

Post with `bkt pr comment` using the approved file, line side, and text. Include
`--project`, `--repo`, or `--workspace` when needed. One command per comment.
Report success or per-comment failures. Do not approve, merge, or resolve threads
unless separately requested.
