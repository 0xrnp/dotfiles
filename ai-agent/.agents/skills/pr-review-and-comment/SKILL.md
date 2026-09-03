---
name: pr-review-and-comment
description: >-
  Review someone else's Bitbucket pull request and post inline comments after a
  mandatory preview. Use for /pr-review-and-comment, or when Rudra asks to
  review a PR and post comments in one step.
disable-model-invocation: true
---

# PR review and comment (Bitbucket)

Use when Rudra runs `/pr-review-and-comment` or asks to review a Bitbucket PR
and post inline comments. This skill authorizes posting comments only after the
preview gate below. It does not authorize approve, merge, decline, or code edits.

## Review phase

Complete **Resolve the PR**, **Inspect**, **Review**, and **Report** from
`pr-review` for the same PR target. Build a proposed inline comment for every
finding Rudra would reasonably want on the PR. Skip nits unless the PR is small
or Rudra asked for exhaustive feedback.

Map each comment to `bkt` inline flags:

- Side `to`: `bkt pr comment <id> --text "..." --file <path> --to-line <n>`
- Side `from`: `bkt pr comment <id> --text "..." --file <path> --from-line <n>`

Include `--project`, `--repo`, or `--workspace` when the active context does not
match the PR. Pass comment bodies unchanged from the approved preview. Do not
use `--pending` unless Rudra explicitly asked for draft comments.

## Comment preview gate

Before any `bkt pr comment` command, show:

1. PR host, project or workspace, repo, id, title, source to target.
2. Count of inline comments to post.
3. A numbered list. For each comment show: finding ID, file, line, side
   (`to` or `from`), severity, and the **exact** markdown body that will be
   posted.
4. End with:
   `Waiting to post N inline comment(s) on <project-or-workspace>/<repo> PR #<id>.`

Stop for separate explicit authorization. After this preview is pending,
`gooo` / `okgo` / `yes` / "post the comments" authorizes that preview only.
Re-check the PR head and diff if the branch moved; any change requires a new
preview.

## Execute

Post comments in severity order (`blocker` first). One `bkt pr comment` per
finding. Use the approved text verbatim. Do not add AI attribution.

After posting, report each comment's returned id when JSON output is available,
or confirm success per comment. If a line anchor fails (outdated diff), report
the failure, skip that comment, and list it for manual placement.

Do not approve, merge, decline, resolve threads, or edit the PR description
unless separately requested.
