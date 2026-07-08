#!/bin/bash
# Install and configure TUI stack: tmux, Neovim, oterm, misc tools

set -e

echo "==> Installing base TUI tools"
sudo apt-get update
sudo apt-get install -y \
  tmux \
  git \
  curl \
  ripgrep \
  fd-find \
  fzf \
  bat \
  htop \
  btop \
  jq \
  unzip

echo "==> Installing Neovim (latest AppImage — JetPack apt version is too old)"
curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim-linux-aarch64.appimage
chmod +x nvim-linux-aarch64.appimage
sudo mv nvim-linux-aarch64.appimage /usr/local/bin/nvim

echo "==> Installing oterm (Ollama TUI)"
pip3 install oterm

echo "==> Installing llm CLI (Simon Willison)"
pip3 install llm
llm install llm-ollama

echo "==> Writing tmux config"
cat > ~/.tmux.conf <<'EOF'
set -g default-terminal "tmux-256color"
set -ag terminal-overrides ",xterm-256color:RGB"
set -g mouse on
set -g base-index 1
setw -g pane-base-index 1
set -g renumber-windows on
set -g history-limit 50000
set -g status-position top

# Prefix: Ctrl-a
unbind C-b
set -g prefix C-a
bind C-a send-prefix

# Splits
bind | split-window -h -c "#{pane_current_path}"
bind - split-window -v -c "#{pane_current_path}"

# Vim-style pane navigation
bind h select-pane -L
bind j select-pane -D
bind k select-pane -U
bind l select-pane -R

# Status bar
set -g status-style 'bg=#1a1a2e fg=#e0e0e0'
set -g status-left '#[fg=#00ff99,bold] ⬡ CYBERDECK #[default] '
set -g status-right '#[fg=#888888]%H:%M %d-%b #[default]'
set -g window-status-current-style 'fg=#00ff99,bold'
EOF

echo "==> Writing .bashrc additions"
cat >> ~/.bashrc <<'EOF'

# Cyberdeck aliases
alias vi='nvim'
alias vim='nvim'
alias ai='oterm'
alias mesh='nomadnet'
alias ll='ls -la'
alias bat='batcat'

# Auto-attach tmux on login
if command -v tmux &>/dev/null && [ -z "$TMUX" ]; then
  tmux attach -t main 2>/dev/null || tmux new -s main
fi
EOF

echo "==> TUI stack installed."
echo "    Commands: nvim, oterm (Ollama TUI), nomadnet (mesh), tmux"
echo "    Aliases:  ai, mesh"
echo "    Re-source shell: source ~/.bashrc"
