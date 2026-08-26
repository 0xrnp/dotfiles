# Personal AI standards

Tracked in `~/dotfiles/ai-agent` (GNU Stow). Edit there; live paths are symlinks into `$HOME`.

Nothing here is meant for work repos. Do not copy into project `.cursor/` unless you explicitly want teammates to inherit it.

## Layout

| Path | Role |
|------|------|
| `~/ai-standards/universal.md` | Source of truth — how to think and work |
| `~/ai-standards/approve-phrases.txt` | ALL CAPS phrases that unlock edits |
| `~/ai-standards/cursor-user-rules.md` | Optional paste into Cursor → Customize → Rules |
| `~/.cursor/hooks/` + `hooks.json` | Hard gates (shell + MCP + plan-first) + session inject |
| `~/.claude/CLAUDE.md` | Claude Code always-on pointer |
| `~/.config/opencode/AGENTS.md` | OpenCode always-on pointer (stow package `opencode`) |

## Stow (this machine / fresh Mac)

```bash
cd ~/dotfiles
stow --target="$HOME" ai-agent
~/ai-standards/check.sh
```

Tracked `hooks.json` is the **portable core** only (your gates). Third-party hooks (Orca / Superset / herdr) are installed by those tools and are not in this package.

## What loads automatically

1. **Cursor**: `sessionStart` injects `universal.md` + approval phrases. Hooks gate dangerous shell, mutating MCP, secret reads, and **plan-first edits** (Write blocked until an ALL CAPS phrase from `approve-phrases.txt`).
2. **Claude Code**: reads `~/.claude/CLAUDE.md`.
3. **OpenCode**: reads `AGENTS.md` next to `opencode.json` when present.

Verify anytime: `~/ai-standards/check.sh`

### Attribution (Co-authored-by Cursor)

- CLI: `~/.cursor/cli-config.json` → `attribution.attributeCommitsToAgent/PRs: false`
- Shell hook: **denies** commits/PRs whose command includes Cursor co-author / `@cursor.com` trailers
- Also turn off in UI: **Cursor Settings → Git & PRs → Attribution** (IDE injects trailers outside the shell sometimes)

Opt-in (noisy): add `./hooks/dod-stop.sh` to `stop` in `~/.cursor/hooks.json` for a one-shot DoD follow-up after each completed agent turn.

## Edit once

Change `~/dotfiles/ai-agent/ai-standards/universal.md` or `approve-phrases.txt` (live via symlink). Agents pick standards up on the next session; phrase list is live for the next prompt.

## Optional: Cursor User Rules UI

If you want account-synced rules as a backup, paste `cursor-user-rules.md` into **Cursor → Customize → Rules**. Not required if hooks are working.
