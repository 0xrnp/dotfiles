# 0xrnp/dotfiles

My personal dotfiles for macOS, managed with [GNU Stow](https://www.gnu.org/software/stow/).

## What's inside

| Tool | What it does |
|---|---|
| `aerospace` | Window manager |
| `atuin` | Shell history search |
| `bat` | Better `cat` |
| `borders` | Window borders |
| `btop` | System monitor |
| `cursor` | Cursor editor |
| `eza` | Better `ls` |
| `flutter` | Flutter SDK config |
| `ghostty` | Terminal emulator |
| `htop` | Process viewer |
| `jgit` | Git helper |
| `lazygit` | Git TUI |
| `nvim` | Neovim editor |
| `opencode` | AI coding tool |
| `raycast` | Spotlight replacement |
| `sketchybar` | Menu bar customizer |
| `swiftpm` | Swift package manager |
| `yazi` | File manager |
| `zed` | Zed editor |
| `zellij` | Terminal multiplexer |

## Fresh Mac Setup

### 1. Install Homebrew

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

### 2. Install core tools

```bash
brew install stow git zsh
```

### 3. Install your tools

```bash
brew install neovim lazygit yazi eza bat btop htop atuin zellij
brew install --cask ghostty zed cursor aerospace raycast
```

### 4. Set up SSH key for GitHub

```bash
# Generate personal SSH key
ssh-keygen -t ed25519 -C "rnp.rudranarayanpanda@gmail.com" -f ~/.ssh/id_github_personal

# Add to SSH agent
ssh-add ~/.ssh/id_github_personal

# Print public key — copy and add to GitHub → Settings → SSH Keys
cat ~/.ssh/id_github_personal.pub
```

Add this to `~/.ssh/config`:

```
# Personal GitHub
Host github-personal
  HostName github.com
  User git
  IdentityFile ~/.ssh/id_github_personal
```

### 5. Clone this repo

```bash
git clone git@github-personal:0xrnp/dotfiles.git ~/dotfiles
```

### 6. Stow everything

```bash
cd ~/dotfiles

for tool in aerospace atuin bat borders btop cursor eza flutter ghostty htop jgit lazygit nvim opencode raycast sketchybar swiftpm yazi zed zellij; do
  stow --adopt --target="$HOME" "$tool"
done
```

### 7. Verify symlinks

```bash
ls -la ~/.config | grep "\->"
```

Every tool should show an arrow pointing to `~/dotfiles`.

---

## Day-to-day usage

### Making a change

Just edit files inside `~/dotfiles` directly — changes are live instantly because of symlinks.

```bash
# Example: edit ghostty config
nvim ~/dotfiles/ghostty/.config/ghostty/config

# Commit and push
cd ~/dotfiles
git add .
git commit -m "feat: update ghostty config"
git push
```

### Adding a new tool's config

```bash
# 1. Create the stow structure
mkdir -p ~/dotfiles/newtool/.config/newtool

# 2. Move the existing config in
mv ~/.config/newtool ~/dotfiles/newtool/.config/

# 3. Stow it
cd ~/dotfiles
stow --target="$HOME" newtool

# 4. Commit
git add newtool
git commit -m "feat: add newtool config"
git push
```

### Pulling updates on another machine

```bash
cd ~/dotfiles
git pull

for tool in aerospace atuin bat borders btop cursor eza flutter ghostty htop jgit lazygit nvim opencode raycast sketchybar swiftpm yazi zed zellij; do
  stow --adopt --target="$HOME" "$tool"
done
```

---

## SSH config for work + personal

This setup uses `github-personal` as the SSH host so it never conflicts with company git configs.

```
# Company (Bitbucket) — global git config
Host bitbucket.org
  IdentityFile ~/.ssh/id_ed25519

# Personal (GitHub)
Host github-personal
  HostName github.com
  User git
  IdentityFile ~/.ssh/id_ed25519_personal
```

Cloning personal repos always uses:
```bash
git clone git@github-personal:0xrnp/reponame.git
```

---

## Troubleshooting

**Stow conflict error:**
```bash
# Use --adopt to pull in any existing files
stow --adopt --target="$HOME" <toolname>
```

**Symlink not working:**
```bash
# Remove the old file/folder and restow
rm -rf ~/.config/<toolname>
stow --target="$HOME" <toolname>
```

**Check all symlinks at once:**
```bash
ls -la ~/.config | grep "\->"
```
