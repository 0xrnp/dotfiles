# Personal AI standards

This repository is the portable source for Rudra's coding-agent behavior. GNU
Stow exposes tracked files under `$HOME`; the installer reconciles live
Claude and Codex settings without replacing other integrations.

Personal configuration stays out of work repositories unless a project rule is
intended for the whole team.

## Sources of truth

| Path | Purpose |
|---|---|
| `~/ai-standards/AGENTS.md` | Concise universal engineering and workflow policy |
| `~/.agents/skills/` | Portable, on-demand Agent Skills |
| `~/.cursor/hooks.json` | Cursor enforcement and context injection |
| `~/.claude/CLAUDE.md` | Claude import and skill routing |
| `~/.codex/AGENTS.md` | Codex pointer to the canonical policy |
| `~/.pi/agent/AGENTS.md` | Pi pointer to the canonical policy |
| `~/.pi/agent/extensions/ai-standards.ts` | Pi per-action safety checks |
| `~/.config/opencode/AGENTS.md` | OpenCode pointer to the canonical policy |

Repository instructions override personal skills for architecture, commands,
versions, and local conventions.

## Install on this or a new machine

Clone the dotfiles repository at `~/dotfiles`, install GNU Stow, Python 3,
`jq`, and Node.js 22.19+ (for the Pi regression tests), then run:

```bash
~/dotfiles/ai-agent/ai-standards/bootstrap.sh
```

The bootstrap:

1. Restows `ai-agent`, `codex`, and `opencode`.
2. Removes only the legacy personal plan-gate hooks from Claude and Codex
   without replacing Orca, Superset, Herdr, marketplace, or local settings.
3. Exposes Pi's global context file and per-action safety extension without
   changing Pi providers, models, packages, or credentials.
4. Runs the complete configuration check.

Run `~/ai-standards/check.sh` at any time to detect broken links, stale
references, invalid JSON, missing skills, or safety-hook regressions.

## How updates are tracked

Edit files through their live symlinks or under `~/dotfiles`. Both paths modify
the same tracked file, so `git diff` shows changes immediately. Git commits
remain explicit. The setup never commits configuration automatically.

Claude and Codex settings are exceptions because integrations also modify those
JSON files. `install-agent-hooks.py` removes only the old tracked gate commands
idempotently. The full live settings files are not copied into this package.

## Skills and context

Agents initially see skill names and short descriptions. They load a
`SKILL.md` body only when the task matches. `using-skill-guide` routes by task,
language, and repository without loading every skill.

Primary language skills cover JavaScript/TypeScript, Dart/Flutter, Python,
Terraform/HCL, and Rust. Cross-cutting skills cover contracts, stored shape,
system design, impact analysis, MongoDB aggregation, prose, final review,
systematic debugging, verification before completion, security hardening, and
Bitbucket PR review (`pr-review`, `pr-review-and-comment`, `add-pr-comments`).
Homes-specific skills apply only in Homes repositories.

Add a skill only for a repeated workflow or non-obvious domain constraint.
Keep the main file small, include when not to use it, and move detailed
reference material into one-hop `references/` files only when needed.

Do not vendor full third-party skill packs into this tree. They fight the
canonical `AGENTS.md` workflow. Optional full installs stay outside this
package, for example [obra/superpowers](https://github.com/obra/superpowers),
[addyosmani/agent-skills](https://github.com/addyosmani/agent-skills), or
[anthropics/skills](https://github.com/anthropics/skills) via each product's
installer or `npx skills add …`.

## Enforcement limits

The canonical policy asks agents to inspect and present a scoped plan before
non-trivial changes, then implement and verify in the same turn. The plan is
visible context, not a hard permission unlock. Hosts may batch progress messages,
so this does not guarantee that Rudra saw a plan before the first edit. Use a
host's Plan mode when a review pause is wanted.

Cursor keeps shell, MCP, and read safety hooks, but no prompt-session or
local-edit approval gate. Its shell hook blocks catastrophic commands and asks
before commits, pushes, publish, infra apply, recursive force-delete, or secret
reads. Its MCP hook asks before mutating or privileged calls. These checks apply
only where Cursor loads local user hooks; they do not cover Cursor Cloud Agents,
remote workers, or Tab. Cursor ACP in Zed does not need a bound
`beforeSubmitPrompt` event for ordinary editing.

Claude and Codex use their own sandbox and approval controls. The installer
removes only the old personal prompt/tool/stop gate commands from their live
settings. It leaves third-party hooks untouched.

Pi's extension runs the same shell and MCP safety hooks before relevant tool
calls. An `ask` decision uses Pi's interactive or RPC confirmation UI; without
one, it blocks. Local edit tools proceed without a token. Pi has no built-in
sandbox, and neither this extension nor a Git worktree restricts arbitrary
filesystem access. Cursor SDK native tools still use Cursor's local safety
hooks when user hooks are enabled. Other extensions or custom tools can have
side effects that these name-based checks cannot identify.

The old `approval-gate.py` and `approve-phrases.txt` are retained but inactive,
so the pending work on them is not discarded. Offline checks verify configuration
and hook decisions; they do not send model requests or prove end-to-end ACP
behavior. Use an operating-system sandbox or container for untrusted work.

## Secrets

Do not track credentials, tokens, `.env` files, MCP authentication, agent
sessions, caches, generated marketplace content, or machine authentication
state. Keep examples credential-free.

## Attribution

Cursor commit and PR attribution is disabled in CLI configuration and guarded
by the shell hook. Also disable it in Cursor Settings under Git and PRs because
the IDE can add attribution outside the shell.

Cursor can still inject its commit trailer before shell execution even when
both settings are disabled. The Shell `preToolUse` hook removes only the exact
Cursor trailer before the shell safety gate evaluates the command.
