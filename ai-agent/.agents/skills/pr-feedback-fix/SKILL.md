---
name: pr-feedback-fix
description: >-
  Fix the actionable review comments on Rudra's own Bitbucket pull request in
  the local checkout. Does not reply or resolve threads. Use for
  /pr-feedback-fix or "fix the comments on my PR".
---

# PR feedback: fix

Step 2 of the flow: `pr-feedback`, `pr-feedback-fix`, `pr-feedback-resolve`.
Use when Rudra asks to fix the comments on his own PR. This edits local files
only. It does not reply, resolve threads, commit, push, approve, or merge.

## Steps

1. Run the fetch and categorize steps of `pr-feedback` (own-PR check included).
   Reuse the report from the same chat if the PR head has not changed.
2. Require the PR source branch checked out and a working tree safe to edit.
   Otherwise stop after the report and say why.
3. Apply code changes for `fix` and `fix-small` threads only, with the smallest
   edit each. No unrelated cleanup. Do not edit `question`, `disagree`, or
   `unclear` threads.
4. Run the narrowest meaningful check for the changed files and report the real
   result.

## Report

Per thread: category, files edited, check result, and one of:

- `fixed locally`: edit applied and check did not fail.
- `not fixed`: edit failed, check failed, or the right change is unclear. Say why.
- `untouched`: `question`, `disagree`, `unclear`, `already-done`, `info`.

Remind Rudra the fixes are uncommitted and unpushed. Next steps: commit and
push (`commit-authoring`), then `pr-feedback-resolve`.
