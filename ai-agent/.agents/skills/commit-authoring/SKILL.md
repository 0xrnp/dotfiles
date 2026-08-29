---
name: commit-authoring
description: >-
  Prepares and creates evidence-based Git commits with a mandatory message
  preview. Use when drafting a commit message, choosing what commit msg to
  give, or before creating or amending a commit (slash, named skill, or
  natural language).
---

# Commit authoring

Repository instructions and established commit conventions win. This skill
does not authorize staging, committing, amending, or pushing.

## Inspect

- Read repository guidance and enough recent commit subjects to identify the
  local message style without copying unrelated wording.
- Inspect the complete staged diff and diffstat. That is the proposed commit.
- Report unstaged and untracked work separately because it will be excluded.
- If nothing is staged and intent is unclear, stop. Do not imply that
  working-tree changes will be committed.
- If nothing is staged but the chat clearly points at specific just-finished
  work, propose the exact `git add` paths and stop. Do not stage without
  approval.
- If the staged diff contains unrelated concerns, explain the split before
  proposing commits. Do not change the index without approval.
- Gather issue context and verification evidence. Do not invent either.

## Draft

Write a concise subject that states the outcome and scope. Follow the
repository's capitalization, prefix, ticket, tense, and length conventions.

Add a body only when it helps a future reader understand:

- why the change was necessary;
- behavior or contracts that changed;
- a non-obvious decision, constraint, or trade-off;
- migration, compatibility, rollout, or follow-up context.

Do not narrate the diff, list every file, claim unrun checks, add an unsupported
ticket, or include AI attribution. Apply the `unslop` skill to a multi-line
message.

## Preview gate

Before any commit write, show:

1. Staged files and diffstat.
2. Unstaged and untracked work that is excluded.
3. The exact subject and complete body with formatting preserved.
4. Whether the operation creates or amends a commit.
5. End with: `Waiting to commit with the message above.`

Stop for separate explicit authorization. After this preview is pending,
`gooo` / `okgo` / `yes` / "commit it" authorizes that preview only, not a new
implement unlock unless the message also changes scope. Immediately before
execution, re-check the staged content and message. Any change requires a new
preview and authorization.

## Execute

- Pass the approved message non-interactively and unchanged.
- Do not bypass hooks.
- Amend only when explicitly requested and when rewriting that commit is safe
  under the global and repository instructions.
- After success, inspect the created commit and report its hash and subject.
- Do not push unless separately requested and authorized.
