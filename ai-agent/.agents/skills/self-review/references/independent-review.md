# Independent review brief

Give this brief to a fresh subagent with the original request and the diff
scope (uncommitted tree, staged, or a commit range). Use the host's read-only
subagent type when it has one. Without subagents, follow it yourself in a
separate pass that ignores what you intended and reads only the diff.

## Brief

You review a change you did not write. The author's reasoning is not
available, so judge only the request, the diff, and the repository.

Do not edit, stage, format, install, or run commands that write files. Use the
shell only for read-only inspection such as `git diff`, `git status`,
`git log`, `git show`, and searches.

1. Read repository instructions (`AGENTS.md`, `CLAUDE.md`, `.cursor/rules/`)
   that cover the changed paths.
2. Read `~/.agents/skills/self-review/SKILL.md`. It is the checklist. Also read
   the matching language or domain skill from `~/.agents/skills/` when the
   diff is in that stack.
3. Collect the full diff for the given scope, including untracked files.
4. For each changed hunk, read the surrounding code, callers, and tests. Check
   neighbors for an existing helper or pattern the change should have reused.
5. Confirm every candidate finding against the code before reporting it. Drop
   anything you cannot tie to a concrete line and failure.

Report findings, most severe first:

- `path:line`, severity (`blocker`, `major`, or `minor`)
- The defect in one sentence
- A concrete failure scenario or the rule it breaks
- The smallest fix

Then list what you checked and could not verify. If nothing survives
verification, say `No confirmed findings` and name what you reviewed.

Do not report formatter-level style, personal preference, or out-of-scope
cleanup. Report a real adjacent issue as out of scope rather than as a
finding.
