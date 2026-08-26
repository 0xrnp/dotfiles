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

# Terraform aliases
alias tf="terraform"
alias tfi="terraform init"
alias tfp="terraform plan"
alias tfa="terraform apply"
alias tfd="terraform destroy"
alias tfv="terraform validate"
alias tff="terraform fmt -recursive"
alias tfo="terraform output"
alias tfs="terraform show"
alias tfsl="terraform state list"
alias tfsh="terraform state show"
alias tfsm="terraform state mv"
alias tfsr="terraform state rm"
alias tfimp="terraform import"
alias tfr="terraform refresh"
alias tfw="terraform workspace"
alias tfws="terraform workspace select"
alias tfwl="terraform workspace list"
alias tfwn="terraform workspace new"
alias tfu="terraform force-unlock"
alias tfc="terraform console"
alias tfg="terraform graph"
alias tfclean="rm -rf .terraform .terraform.lock.hcl"

# Editor + FZF pickers
alias vim=nvim
alias vi=nvim
alias ff='nvim $(fzf -m --preview="bat --color=always {}")'
alias tvf='nvim $(tv files)'
alias tx=tmux
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

# 4. mise — Node + Python only. Flutter stays on FVM; Rust on rustup.
eval "$(/Users/rudranarayan/.local/bin/mise activate zsh)"

# Old nvm lazy-load kept commented in case you need a one-off fallback:
# export NVM_DIR="$HOME/.nvm"
# nvm() {
#     unset -f nvm node npm npx yarn
#     [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
#     [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
#     nvm "$@"
# }
# node() { unset -f nvm node npm npx; [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"; node "$@"; }
# npm() { unset -f nvm node npm npx; [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"; npm "$@"; }
# npx() { unset -f nvm node npm npx; [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"; npx "$@"; }

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
# FPATH=$HOMEBREW_PREFIX/share/zsh-completions:$FPATH
# autoload -Uz compinit
# compinit -d "$XDG_CONFIG_HOME/zsh/zcompdump-$ZSH_VERSION" # Saves the dump file away from home root

# 7. Completions (Optimized lookup & 24hr cache)
FPATH=$HOMEBREW_PREFIX/share/zsh-completions:$FPATH
autoload -Uz compinit
# Only rebuild zcompdump once a day
if [[ -n "$XDG_CONFIG_HOME/zsh/zcompdump-$ZSH_VERSION"(#qN.mh+24) ]]; then
  compinit -d "$XDG_CONFIG_HOME/zsh/zcompdump-$ZSH_VERSION"
else
  compinit -C -d "$XDG_CONFIG_HOME/zsh/zcompdump-$ZSH_VERSION"
fi

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

# fastfetch (Run if launched in Ghostty or Alacritty)
if [[ -n "$GHOSTTY_RESOURCES_DIR" || -n "$ALACRITTY_WINDOW_ID" ]]; then
  fastfetch
fi

# Java
export JAVA_HOME=$(/usr/libexec/java_home -v 21)
export PATH="$JAVA_HOME/bin:$PATH"

# AWS Profile
export AWS_PROFILE=homes-developer-737866084260
