# Personal AI standards

This repository is the portable source for Rudra's coding-agent behavior. GNU
Stow exposes tracked files under `$HOME`; product-specific installers merge only
the hook entries that cannot safely be symlinked.

Personal configuration stays out of work repositories unless a project rule is
intended for the whole team.

## Sources of truth

| Path | Purpose |
|---|---|
| `~/ai-standards/AGENTS.md` | Concise universal engineering and workflow policy |
| `~/ai-standards/approve-phrases.txt` | Standalone tokens that unlock the current turn |
| `~/.agents/skills/` | Portable, on-demand Agent Skills |
| `~/.cursor/hooks.json` | Cursor enforcement and context injection |
| `~/.claude/CLAUDE.md` | Claude import and skill routing |
| `~/.codex/AGENTS.md` | Codex pointer to the canonical policy |
| `~/.config/opencode/AGENTS.md` | OpenCode pointer to the canonical policy |

Repository instructions override personal skills for architecture, commands,
versions, and local conventions.

## Install on this or a new machine

Clone the dotfiles repository at `~/dotfiles`, install GNU Stow and Python 3,
then run:

```bash
~/dotfiles/ai-agent/ai-standards/bootstrap.sh
```

The bootstrap:

1. Restows `ai-agent`, `codex`, and `opencode`.
2. Adds personal `UserPromptSubmit` and `PreToolUse` hooks to Claude and Codex
   without replacing Orca, Superset, Herdr, marketplace, or local settings.
3. Runs the complete configuration check.

Run `~/ai-standards/check.sh` at any time to detect broken links, stale
references, invalid JSON, missing skills, or approval-gate regressions.

## How updates are tracked

Edit files through their live symlinks or under `~/dotfiles`. Both paths modify
the same tracked file, so `git diff` shows changes immediately. Git commits
remain explicit. The setup never commits configuration automatically.

Claude and Codex settings are exceptions because integrations also modify those
JSON files. `install-agent-hooks.py` merges tracked hook commands
idempotently. The full live settings files are not copied into this package.

## Skills and context

Agents initially see skill names and short descriptions. They load a
`SKILL.md` body only when the task matches. `using-skill-guide` routes by task,
language, and repository without loading every skill.

Primary language skills cover JavaScript/TypeScript, Dart/Flutter, Python,
Terraform/HCL, and Rust. Cross-cutting skills cover contracts, stored shape,
system design, impact analysis, MongoDB aggregation, prose, and final review.
Homes-specific skills apply only in Homes repositories.

Add a skill only for a repeated workflow or non-obvious domain constraint.
Keep the main file small, include when not to use it, and move detailed
reference material into one-hop `references/` files only when needed.

## Enforcement limits

Hooks prevent supported mutating tools from running before a standalone
approval token. They re-lock on each user prompt. Read-only shell commands
remain available for inspection.

Hooks cannot prove that a design is correct or reliably extract a file allowlist
from an assistant's prose plan. Repository tests, type systems, linters, CI,
diff review, and human judgment remain required.

Cursor user hooks do not reach Cursor Cloud Agents, remote workers, or Tab.
Those environments need project or managed policy if the same hard controls are
required.

## Secrets

Do not track credentials, tokens, `.env` files, MCP authentication, agent
sessions, caches, generated marketplace content, or machine authentication
state. Keep examples credential-free.

## Attribution

Cursor commit and PR attribution is disabled in CLI configuration and guarded
by the shell hook. Also disable it in Cursor Settings under Git and PRs because
the IDE can add attribution outside the shell.
