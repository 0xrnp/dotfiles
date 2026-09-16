#!/usr/bin/env bash
set -euo pipefail

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)
dotfiles_root=$(CDPATH= cd -- "$script_dir/../.." && pwd -P)

command -v stow >/dev/null 2>&1 || {
  printf '%s\n' "GNU Stow is required."
  exit 1
}
command -v python3 >/dev/null 2>&1 || {
  printf '%s\n' "Python 3 is required."
  exit 1
}
command -v jq >/dev/null 2>&1 || {
  printf '%s\n' "jq is required."
  exit 1
}

legacy_cursor_skills=(
  blast-radius homes-flutter homes-git homes-js-ts mongo-aggregations
  react-native schema-design self-review unslop using-skill-guide
)
for skill in "${legacy_cursor_skills[@]}"; do
  legacy="$HOME/.cursor/skills/$skill"
  if [[ -L "$legacy" && ! -e "$legacy" ]]; then
    unlink "$legacy"
  fi
done

stow --dir="$dotfiles_root" --target="$HOME" --restow ai-agent codex
python3 "$HOME/ai-standards/install-agent-hooks.py"
"$HOME/ai-standards/check.sh"
