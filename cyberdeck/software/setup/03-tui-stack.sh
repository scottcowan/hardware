#!/bin/bash
# Install and configure TUI stack — Omarchy-inspired for JetPack aarch64
# Pulls portable core from Omarchy: tmux config, bash shell, starship, lazygit, LazyVim

set -e

echo "==> Installing base TUI tools"
sudo apt-get update
sudo apt-get install -y \
  tmux \
  git \
  curl \
  wget \
  ripgrep \
  fd-find \
  fzf \
  bat \
  btop \
  jq \
  unzip \
  zoxide \
  lazygit \
  npm

echo "==> Installing Neovim (latest aarch64 AppImage)"
NVIM_URL=$(curl -s https://api.github.com/repos/neovim/neovim/releases/latest \
  | grep "browser_download_url.*nvim-linux-aarch64.appimage\"" \
  | cut -d '"' -f 4)
curl -L "$NVIM_URL" -o /tmp/nvim.appimage
chmod +x /tmp/nvim.appimage
sudo mv /tmp/nvim.appimage /usr/local/bin/nvim

echo "==> Installing starship prompt (aarch64)"
curl -sS https://starship.rs/install.sh | sh -s -- --yes

echo "==> Installing eza (modern ls, aarch64)"
sudo mkdir -p /etc/apt/keyrings
wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc \
  | sudo gpg --dearmor -o /etc/apt/keyrings/gierens.gpg
echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" \
  | sudo tee /etc/apt/sources.list.d/gierens.list
sudo apt-get update && sudo apt-get install -y eza

echo "==> Installing mise (language version manager)"
curl https://mise.run | sh

echo "==> Installing oterm (Ollama TUI)"
pip3 install oterm

echo "==> Installing llm CLI (Simon Willison)"
pip3 install llm
llm install llm-ollama

echo "==> Writing tmux config (Omarchy-style)"
cat > ~/.tmux.conf <<'EOF'
# Omarchy-inspired tmux config — adapted for cyberdeck aarch64

set -g default-terminal "tmux-256color"
set -ag terminal-overrides ",xterm-256color:RGB"
set -g mouse on
set -g base-index 1
setw -g pane-base-index 1
set -g renumber-windows on
set -g history-limit 50000
set -g status-position top
set -g set-clipboard on
set -g mode-keys vi

# Prefix: Space (Omarchy default)
unbind C-b
set -g prefix C-Space
bind C-Space send-prefix

# Splits — stay in current path
bind | split-window -h -c "#{pane_current_path}"
bind - split-window -v -c "#{pane_current_path}"
bind c new-window -c "#{pane_current_path}"

# Vim-style pane navigation
bind h select-pane -L
bind j select-pane -D
bind k select-pane -U
bind l select-pane -R

# Resize panes
bind -r H resize-pane -L 5
bind -r J resize-pane -D 5
bind -r K resize-pane -U 5
bind -r L resize-pane -R 5

# Vi copy mode
bind-key -T copy-mode-vi v send-keys -X begin-selection
bind-key -T copy-mode-vi y send-keys -X copy-selection-and-cancel

# Quick session layouts (from Omarchy tmux functions)
bind D new-session \; split-window -h -p 35 \; select-pane -L
bind G new-session \; split-window -h -p 35 \; send-keys -t right "lazygit" Enter \; select-pane -L

# Status bar — cyberdeck theme
set -g status-style 'bg=#1a1a2e fg=#a9b1d6'
set -g status-left-length 40
set -g status-right-length 60
set -g status-left '#[fg=#7aa2f7,bold] ⬡ CYBERDECK #[fg=#565f89]| #[default]'
set -g status-right '#[fg=#565f89]#{?client_prefix,#[fg=#e0af68]PREFIX ,}#[fg=#565f89]%H:%M #[fg=#7aa2f7]%d-%b'
set -g window-status-format '#[fg=#565f89] #I:#W '
set -g window-status-current-format '#[fg=#7aa2f7,bold] #I:#W '
set -g pane-border-style 'fg=#1a1b26'
set -g pane-active-border-style 'fg=#7aa2f7'
set -g message-style 'bg=#1a1a2e fg=#7aa2f7'
EOF

echo "==> Writing starship config (Omarchy-style minimal)"
mkdir -p ~/.config
cat > ~/.config/starship.toml <<'EOF'
# Omarchy-inspired starship config
format = "$directory$git_branch$git_status$character"

[directory]
style = "cyan bold"
truncation_length = 3
truncate_to_repo = true

[git_branch]
format = "[$branch]($style) "
style = "green"

[git_status]
format = '([$all_status$ahead_behind]($style) )'
style = "yellow"

[character]
success_symbol = "[❯](green)"
error_symbol = "[❯](red)"

[line_break]
disabled = true
EOF

echo "==> Writing git config (Omarchy defaults)"
git config --global core.autocrlf input
git config --global diff.algorithm histogram
git config --global pull.rebase true
git config --global rerere.enabled true
git config --global branch.sort -committerdate
git config --global init.defaultBranch main

echo "==> Installing LazyVim for Neovim"
# Backup existing nvim config if present
[ -d ~/.config/nvim ] && mv ~/.config/nvim ~/.config/nvim.bak.$(date +%s)
[ -d ~/.local/share/nvim ] && mv ~/.local/share/nvim ~/.local/share/nvim.bak.$(date +%s)

git clone https://github.com/LazyVim/starter ~/.config/nvim
rm -rf ~/.config/nvim/.git

# Cyberdeck extras on top of LazyVim base
mkdir -p ~/.config/nvim/lua/plugins
cat > ~/.config/nvim/lua/plugins/cyberdeck.lua <<'LUAEOF'
-- Cyberdeck-specific Neovim additions on top of LazyVim
return {
  -- Tokyo Night theme (Omarchy default)
  {
    "folke/tokyonight.nvim",
    lazy = false,
    priority = 1000,
    opts = { style = "night" },
  },
  { "LazyVim/LazyVim", opts = { colorscheme = "tokyonight-night" } },

  -- Ollama integration
  {
    "nomnivore/ollama.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    opts = {
      model = "llama3.2:3b-instruct-q4_K_M",
    },
  },
}
LUAEOF

echo "==> Writing bash config (Omarchy-inspired)"

# Shell config — modular like Omarchy
mkdir -p ~/.config/bash

cat > ~/.config/bash/envs <<'EOF'
export EDITOR=nvim
export VISUAL=nvim
export PAGER="bat --style=plain"
export MANPAGER="sh -c 'col -bx | bat -l man -p'"
export BAT_THEME="ansi"
export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
export FZF_DEFAULT_OPTS='--height 40% --layout=reverse --border'
export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$PATH"
EOF

cat > ~/.config/bash/aliases <<'EOF'
# Navigation — eza (Omarchy ls replacements)
alias ls='eza --icons'
alias ll='eza -la --icons --git'
alias lt='eza --tree --icons -L 2'
alias la='eza -a --icons'

# Editor
alias vi='nvim'
alias vim='nvim'
alias n='nvim'

# Git (Omarchy shortcuts)
alias g='git'
alias gs='git status'
alias gl='git log --oneline -20'
alias gd='git diff'
alias gc='git commit'
alias gp='git push'
alias gpl='git pull'

# Cyberdeck-specific
alias ai='oterm'
alias mesh='nomadnet'
alias power='cat /sys/bus/i2c/drivers/ina3221x/*/iio:device*/in_power0_input 2>/dev/null || sudo tegrastats --interval 1000'
alias maxperf='sudo nvpmodel -m 0 && sudo jetson_clocks'
alias savepower='sudo nvpmodel -m 1'

# Utilities
alias cat='bat'
alias fd='fdfind'
alias lg='lazygit'
EOF

cat > ~/.config/bash/functions <<'EOF'
# fzf file picker → open in nvim (Omarchy n() function)
nf() {
  local file
  file=$(fzf --preview 'bat --color=always --style=numbers {}') && nvim "$file"
}

# cd with fzf (Omarchy zoxide-backed)
cdf() {
  local dir
  dir=$(fd --type d --hidden --exclude .git | fzf) && cd "$dir"
}

# tmux dev layout: editor left, terminal right (Omarchy tdl)
tdl() {
  local session="${1:-dev}"
  tmux new-session -d -s "$session" 2>/dev/null || true
  tmux split-window -h -p 35 -t "$session"
  tmux select-pane -t "$session:0.0"
  tmux attach -t "$session"
}

# tmux dev layout with lazygit on right (Omarchy tdlm)
tdlg() {
  local session="${1:-dev}"
  tmux new-session -d -s "$session" 2>/dev/null || true
  tmux split-window -h -p 35 -t "$session"
  tmux send-keys -t "$session:0.1" "lazygit" Enter
  tmux select-pane -t "$session:0.0"
  tmux attach -t "$session"
}
EOF

cat > ~/.config/bash/init <<'EOF'
# Tool initialisations
eval "$(starship init bash)"
eval "$(zoxide init bash --cmd cd)"
eval "$($HOME/.local/bin/mise activate bash)"
source <(fzf --bash) 2>/dev/null || true
EOF

# Wire everything into .bashrc
cat >> ~/.bashrc <<'EOF'

# Omarchy-inspired modular bash config
for f in envs aliases functions init; do
  [ -f "$HOME/.config/bash/$f" ] && source "$HOME/.config/bash/$f"
done

# Auto-attach tmux on login
if command -v tmux &>/dev/null && [ -z "$TMUX" ]; then
  tmux attach -t main 2>/dev/null || tmux new -s main
fi
EOF

echo "==> TUI stack installed (Omarchy-inspired)."
echo ""
echo "    Tools:   nvim (LazyVim), tmux, starship, eza, zoxide, lazygit, fzf, bat, mise"
echo "    Aliases: ai (oterm), mesh (nomadnet), n (nvim), lg (lazygit), ll, lt"
echo "    Layouts: tdl (editor+terminal), tdlg (editor+lazygit)"
echo "    Prefix:  Ctrl-Space (was Ctrl-a)"
echo ""
echo "    First nvim launch will install LazyVim plugins automatically."
echo "    Re-source shell: source ~/.bashrc"
