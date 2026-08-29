---
name: pr-authoring
description: >-
  Drafts and creates reviewer-ready pull requests with a mandatory preview.
  Use before pushing for, creating, or updating a PR with gh, bkt, or another
  forge CLI, including requests for no reviewers (slash, named skill, or
  natural language).
---

# PR authoring

Repository instructions, PR templates, and established title conventions win.
This skill does not authorize a push, PR creation, or PR update.

## Inspect

- Identify the repository, source branch, target branch, and draft status.
- Read the repository guidance and applicable PR template.
- Review the merge-base diff, diffstat, and every commit that the PR includes,
  not only the latest commit.
- Report staged, unstaged, and untracked work separately because it is not in
  the branch diff.
- Gather linked-ticket context and verification evidence. Do not invent either.
- For an existing PR, inspect its current title, body, state, and target.
- If Rudra asks for no reviewer(s), treat that as a flag on this workflow:
  create or update without assigning reviewers. Do not fork a separate skill.

## Draft

Write a concise title that states the outcome and scope in the repository's
style. Do not copy a branch name or add a ticket that has no supporting context.

Adapt the repository template. Without one, use only the applicable sections:

- Summary: why the change exists and its user or system outcome.
- Changes: meaningful implementation and behavior changes, grouped by area or
  file when that helps the reviewer trace them.
- Reviewer notes: risky paths, decisions, and where review attention matters.
- Verification: exact checks and results. Say `Not run` with the reason when
  necessary.
- Risks and rollout: compatibility, migration, deployment, rollback, or
  follow-up details when relevant.
- Screenshots or recordings for visible UI changes when available.

Detail must come from evidence. Omit empty boilerplate and incidental file
lists. Before finalizing prose, apply the `unslop` skill.

## Preview gate

Before any push or PR write, show:

1. Repository, source to target, draft status, included commits, and diffstat.
2. The exact title.
3. The complete body with formatting preserved.
4. Uncommitted work that is excluded.
5. The pending push and PR actions, including whether reviewers will be omitted.
6. End with: `Waiting to open the PR with the title/body above.`

Stop for separate explicit authorization. After this preview is pending,
`gooo` / `okgo` / `yes` / "open the PR" authorizes that preview only, not a
new implement unlock unless the message also changes scope. If the user revises
the draft, show the complete preview again. Immediately before execution,
re-check HEAD, target, title, and body. Any change requires a new preview and
authorization.

## Execute

- Use explicit source, target, title, and body arguments. Avoid autofill,
  editors, and interactive prompts.
- With `gh`, pass the approved body through `--body-file` and use `--head` so PR
  creation does not perform an implicit push. Omit reviewer flags when the
  no-reviewer flag is set.
- With `bkt`, pass the approved body through `--description` or `--body`.
- Preserve the repository template exactly where it requires fixed sections.
- After creation or update, inspect the resulting PR and return its URL.
