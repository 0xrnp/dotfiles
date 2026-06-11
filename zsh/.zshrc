# Hardcode Homebrew prefix to avoid expensive $(brew --prefix) lookups
export HOMEBREW_PREFIX="/opt/homebrew"
eval "$($HOMEBREW_PREFIX/bin/brew shellenv zsh)"

# Environment Variables
export EDITOR=nvim
export VISUAL=nvim
export XDG_CONFIG_HOME="$HOME/.config"
unset LS_COLORS  # Let eza use its own theme.yml

# Fast PATH extensions
export PATH="$HOME/.local/bin:/Users/rudranarayan/.antigravity/antigravity/bin:$HOME/.pub-cache/bin:$PATH"

# --- Aliases ---
alias lg="lazygit"
alias ld="lazydocker"
alias dc="docker compose"
alias zl="zellij attach -c"
alias cft="cloudflared tunnel"
alias ls="eza --icons --group-directories-first"
alias l="eza --icons --long --group-directories-first --header --git"
alias ll="eza --icons --long --group-directories-first --header --git --inode --blocksize"
alias la="eza --icons --long --group-directories-first --header --git --inode --blocksize --all"
alias lT="eza --icons --tree --group-directories-first --all"
alias lt="eza --icons --tree --group-directories-first"

# Git aliases
alias gc="git commit -m"
alias gca="git commit -a -m"
alias gp="git push origin HEAD"
alias gpu="git pull origin"
alias gst="git status"
alias glog="git log --graph --topo-order --pretty='%w(100,0,6)%C(yellow)%h%C(bold)%C(black)%d %C(cyan)%ar %C(green)%an%n%C(bold)%C(white)%s %N' --abbrev-commit"
alias gdiff="git diff"
alias gco="git checkout"
alias gb="git branch"
alias gba="git branch -a"
alias gadd="git add"
alias ga="git add -p"
alias gcoall="git checkout -- ."
alias gr="git remote"
alias gre="git reset"
alias gwl="git worktree list"
alias gwa="git worktree add"
alias gwr="git worktree remove"

# Editor + FZF pickers
alias vim=nvim
alias vi=nvim
alias ff='nvim $(fzf -m --preview="bat --color=always {}")'
alias tvf='nvim $(tv files)'

export DOCKER_BUILDKIT=1
export COMPOSE_DOCKER_CLI_BUILD=1

# --- Shell Initializations & Optimizations ---

# 1. Fast Starship Init
eval "$(starship init zsh)"

# 2. Fast Zoxide Init
eval "$(zoxide init zsh)"
alias cd=z

# 3. Atuin Init
eval "$(atuin init zsh)"

# 4. nvm
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion


# 5. Zsh Autosuggestions (Using hardcoded Homebrew path)
source "$HOMEBREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh"

# 6. FZF Config & Source
export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude=.git --exclude=Documents --exclude=wallpapers --exclude=Application'
export FZF_DEFAULT_OPTS="\
--color=bg+:#313244,bg:#1E1E2E,spinner:#F5E0DC,hl:#F38BA8 \
--color=fg:#CDD6F4,header:#F38BA8,info:#CBA6F7,pointer:#F5E0DC \
--color=marker:#B4BEFE,fg+:#CDD6F4,prompt:#CBA6F7,hl+:#F38BA8 \
--color=selected-bg:#45475A \
--color=border:#6C7086,label:#CDD6F4"
source <(fzf --zsh)

# 7. Completions (Optimized lookup)
FPATH=$HOMEBREW_PREFIX/share/zsh-completions:$FPATH
autoload -Uz compinit
compinit -d "$XDG_CONFIG_HOME/zsh/zcompdump-$ZSH_VERSION" # Saves the dump file away from home root

# --- Functions & Multiplexers ---

# Yazi 
function y() {
    local tmp="$(mktemp -t yazi-cwd.XXXXXX)"
    command yazi "$@" --cwd-file="$tmp"
    if cwd="$(cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ] && [ -d "$cwd" ]; then
        builtin cd -- "$cwd"
    fi
    rm -f -- "$tmp"
}

# Auto-start Zellij when inside Ghostty (Keep this at the very bottom)
# if [[ -n "$GHOSTTY_RESOURCES_DIR" ]] && [[ -z "$ZELLIJ" ]]; then
#     export ZELLIJ_AUTO_ATTACH=true
#     export ZELLIJ_AUTO_EXIT=true
#     exec zellij attach -c
# fi

fastfetch
