---
name: pr-feedback-resolve
description: >-
  After fixes are pushed, reply in plain text to the review threads on Rudra's
  own Bitbucket pull request and mark the settled ones resolved. Threads that
  need the reviewer to look get a reply only. Posts after a mandatory preview.
  Use for /pr-feedback-resolve or "reply and resolve the comments on my PR".
---

# PR feedback: reply and resolve

Step 3 of the flow: `pr-feedback`, `pr-feedback-fix`, `pr-feedback-resolve`.
Use when Rudra says he is done fixing and wants the threads answered and
closed. Replies are visible to reviewers, so this always previews first. It
edits no code and does not commit, push, approve, or merge.

## Decide each thread

1. Run the fetch and categorize steps of `pr-feedback` (own-PR check included).
   Re-categorize against the current PR head, not an earlier report.
2. For a thread the fix step addressed, confirm the change is actually in the
   PR's current diff (`bkt pr diff`). If it is only local or unpushed, skip the
   thread and say "not pushed yet". Never claim "fixed" for code the reviewer
   cannot see.
3. Assign one action per thread:

| Action | Threads | Result |
|---|---|---|
| `reply + resolve` | `fix`/`fix-small` now in the PR diff, `already-done`, plain-fact `question` | Reply, then mark resolved |
| `reply only` | `disagree`, a `question` the reviewer should judge, any fix that is large or changes behavior | Reply, leave open for the reviewer |
| `skip` | `info`, `unclear`, anything not pushed, anything needing Rudra's decision | No post; list as `needs Rudra` |

When unsure between resolve and reply only, choose reply only. A reviewer can
close a thread; reopening one is noisier.

## Write the replies

Simple words, one to three short sentences, no filler, no em dashes. Say what
was done or why, nothing else. Apply `unslop`. Examples:

- "Good catch. Fixed, the null check is now before the lookup."
- "This already runs in `validate()` on line 40, so I left it here."
- "I kept the old name because the mobile app reads it. Can you confirm that
  works?"

Do not invent facts. If a reply needs Rudra's knowledge, mark it `skip`.

## Preview gate

Before any `bkt` write, show the PR (host, project or workspace, repo, id,
title) and a numbered list with: thread id, file and line, category, action
(`reply + resolve` or `reply only`), and the exact reply. Also list `skip`
threads with the reason. End with:

`Waiting to post N reply(ies) and resolve M thread(s) on <project-or-workspace>/<repo> PR #<id>.`

Stop for explicit authorization. A clear request to post then authorizes that
preview only. If the list, a reply, or the PR head changes, preview again.

## Post

Per approved thread, using the approved text unchanged:

```bash
bkt pr comment <id> --parent <thread-id> --text "<reply>"
bkt pr comments resolve <id> <thread-id>   # reply + resolve only
```

Use the top-level comment id. Resolve only after its reply succeeded. Report
each reply and resolve as posted or failed.
