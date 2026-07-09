#!/bin/bash
# Run all setup scripts in order
# Run as your normal user (not root) — individual scripts sudo where needed
#
# Usage: bash 00-run-all.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "================================================"
echo " Jetson Cyberdeck — first boot setup"
echo "================================================"
echo ""

steps=(
  "01-ollama.sh"
  "02-reticulum.sh"
  "03-tui-stack.sh"
  "04-jetson-tweaks.sh"
  "05-audio.sh"
)

for script in "${steps[@]}"; do
  echo ""
  echo "------------------------------------------------"
  echo " Running: $script"
  echo "------------------------------------------------"
  bash "$SCRIPT_DIR/$script"
done

echo ""
echo "================================================"
echo " Setup complete. Reboot recommended."
echo " After reboot:"
echo "   - Terminal auto-attaches to tmux"
echo "   - 'ai'        → oterm (Ollama TUI)"
echo "   - 'mesh'      → NomadNet (Reticulum)"
echo "   - 'jtop'      → system monitor"
echo "   - 'vq'        → push-to-talk voice query → Llama 3B"
echo "   - 'vw'        → always-on wake word mode"
echo "   - echo hi | tts → text to speech"
echo "   NOTE: Add Porcupine key to ~/.config/porcupine.env for wake word"
echo "================================================"
