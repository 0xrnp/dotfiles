---
name: pr-feedback
description: >-
  Read and categorize review comments on Rudra's own Bitbucket pull request,
  then report. Read-only. Use for /pr-feedback, "check the comments on my PR",
  or a PR id or URL with no request to fix, reply, or resolve.
---

# PR feedback (my PR, report only)

Use when Rudra gives a PR id or URL and wants the comments on his own PR
reviewed. This skill changes nothing: no edits, replies, or thread changes.
Flow: `pr-feedback` (this), then `pr-feedback-fix`, then `pr-feedback-resolve`.
For someone else's PR use `pr-review`.

## Resolve the PR

Accept a numeric id, a Bitbucket URL, or `project/repo#id`. Run
`bkt auth status`, then pass `--project`/`--repo`/`--workspace` when the active
context does not match. Load `~/.cursor/skills/bkt/SKILL.md` if flag details
matter.

Confirm the PR author is Rudra (`bkt pr view <id> --json`). If not, stop and
suggest `pr-review`. Record title, branches, and head commit.

## Fetch

```bash
bkt pr view <id> --json
bkt pr comments <id> --details --json
bkt pr diff <id>
bkt pr checks <id>
```

Group comments into threads by top-level comment id and read each whole thread,
replies included. On Cloud add `--state unresolved`; on Data Center read the
`resolved` and task fields from `--details`. Skip resolved or deleted threads
and say how many.

Use the supplied checkout per `~/ai-standards/AGENTS.md` checkout placement.

## Categorize

Judge each thread against the current code, not the comment's wording. Read the
file at the anchor and check whether the code already changed.

| Category | Meaning |
|---|---|
| `fix` | Valid, needs a code change |
| `fix-small` | Valid nit, naming, typo, or style, trivial change |
| `already-done` | Current head already satisfies it (outdated anchor or later commit) |
| `question` | Reviewer asked something; Rudra must answer |
| `disagree` | Comment looks wrong or conflicts with a contract; Rudra decides |
| `unclear` | Cannot tell what is wanted |
| `info` | Praise, ack, FYI, bot or CI noise; no action |

Verify before calling a comment valid. If the claim is wrong, use `disagree`
and give the evidence. For a `fix` touching shared behavior, think through
`blast-radius`, and load the stack skills `pr-review` lists.

## Report

Start with PR identity, branch pair, CI summary, and counts per category.

| # | Thread | Reviewer | Location | Category | Summary | Proposed action |
|---|---|---|---|---|---|---|
| 1 | 1001 | name | `path:line` | fix | ... | ... |

Then one short note per `fix`, `disagree`, `question`, and `unclear` thread:
the reviewer's point, what the code does, and the concrete change or reply.
End by offering `pr-feedback-fix`.
