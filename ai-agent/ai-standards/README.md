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
| `~/.claude/skills/` | Native discovery links to the owned shared skills |
| `~/.cursor/hooks.json` | Cursor enforcement and context injection |
| `~/.claude/CLAUDE.md` | Claude import and skill routing |
| `~/.codex/AGENTS.md` | Codex pointer to the canonical policy |

Repository instructions override personal skills for architecture, commands,
versions, and local conventions.

## Install on this or a new machine

Clone the dotfiles repository at `~/dotfiles`, install GNU Stow, Python 3,
and `jq`, then run:

```bash
~/dotfiles/ai-agent/ai-standards/bootstrap.sh
```

The bootstrap:

1. Restows `ai-agent` and `codex`.
2. Removes only the legacy personal plan-gate hooks from Claude and Codex
   without replacing Orca, Superset, Herdr, marketplace, or local settings.
3. Links owned skills into Claude's native skill directory. Existing
   unrelated skills are preserved; a conflicting name stops installation.
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
Terraform/HCL, Rust, and Go. Cross-cutting skills cover contracts, stored shape,
system design, impact analysis, MongoDB aggregation, prose, final review,
systematic debugging, verification before completion, security hardening, and
Bitbucket PR review (`pr-review`, `pr-review-and-comment`, `add-pr-comments`).
Homes-specific skills apply only in Homes repositories.

`service-reliability` covers backend failure, concurrency, queue, and recovery
behavior. `delivery-engineering` covers CI, containers, artifact promotion,
rollout, and rollback. Use them when those concerns change, not on every edit.
Version and architecture decisions come from project manifests and local rules;
the Homes stack includes both Flutter apps and the Expo `homes-ecosystem` repo.

Codex and Cursor support the shared user skill directory. Claude uses its native
links. Personal skills permit automatic selection from ordinary task requests;
Rudra does not need to remember skill names or slash commands. Selection loads
guidance, not permission to commit, publish, deploy, or post comments. The
existing request and preview gates still apply. Restart existing agent sessions
after installation so their discovery context reflects changes.

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
before recognized commits, pushes, forge writes, publish, Terraform environment
access, recursive force-delete, or secret reads. Its MCP hook asks before
mutating, privileged, database, or unclassified calls. These checks apply
only where Cursor loads local user hooks; they do not cover Cursor Cloud Agents,
remote workers, or Tab. Cursor ACP in Zed does not need a bound
`beforeSubmitPrompt` event for ordinary editing.

Claude and Codex use their own sandbox and approval controls. The installer
removes only the old personal prompt/tool/stop gate commands from their live
settings. It leaves third-party hooks untouched.

These hooks are best-effort checks, not a security boundary. Shell aliases,
scripts, interpreters, unusual option forms, and tools with misleading names
can escape classification. File-read hooks do not control all shell/search
reads and cannot eliminate filesystem races. Local edit tools still rely on
task scope and host permissions. Use host/OS sandboxing and least-privilege
credentials for actual isolation. A recognized read name does not authorize
access to a live database or production target.

The old `approval-gate.py` and `approve-phrases.txt` are retained but inactive,
so the pending work on them is not discarded. Offline checks verify configuration
and hook decisions; they do not send model requests or prove end-to-end ACP
behavior. Use an operating-system sandbox or container for untrusted work.

## Verification

`check.sh` validates configuration and installed links, tests installer
idempotency/conflict handling, and runs Cursor hook regression cases using
inert commands and synthetic paths. It never executes the represented Git,
infrastructure, or database actions.

[Engineering behavior checks](engineering-evals.md) separately exercise reasoning
about concurrency, idempotency, pagination, compatibility, scope, and authorization.
Keep their results distinct from static validation. A model/host must actually
run a scenario before it can be marked passed.

Discovery references: [Codex](https://developers.openai.com/codex/skills),
[Cursor](https://cursor.com/docs/skills), and [Claude](https://code.claude.com/docs/en/skills).

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
