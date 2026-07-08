#!/bin/bash
# Jetson Orin Nano performance and power tweaks for cyberdeck use

set -e

echo "==> Setting Jetson power mode"
# Mode 0 = MAXN (15W), Mode 1 = 10W
# Use 10W for bench/battery, switch to MAXN for heavy inference
sudo nvpmodel -m 1
echo "    Power mode set to 10W. Use 'sudo nvpmodel -m 0' for max performance."

echo "==> Enabling jetson_clocks persistence across reboots"
sudo systemctl enable nvpmodel

echo "==> Installing jetson-stats (jtop — GPU/CPU/memory monitor)"
sudo pip3 install jetson-stats
echo "    Run 'jtop' for live system monitor"

echo "==> Disabling GUI desktop (we're TUI-only)"
sudo systemctl set-default multi-user.target
echo "    GUI disabled. Re-enable with: sudo systemctl set-default graphical.target"

echo "==> Setting up power measurement alias"
cat >> ~/.bashrc <<'EOF'

# Jetson power monitoring
alias power='cat /sys/bus/i2c/drivers/ina3221x/*/iio:device*/in_power0_input 2>/dev/null || sudo tegrastats --interval 1000'
alias jtop='sudo jtop'
alias nvmode='sudo nvpmodel -q'
alias maxperf='sudo nvpmodel -m 0 && sudo jetson_clocks'
alias savepower='sudo nvpmodel -m 1'
EOF

echo "==> Jetson tweaks applied."
echo "    Run 'jtop' to monitor GPU/CPU/memory/power"
echo "    Run 'maxperf' before heavy inference"
echo "    Run 'savepower' to drop back to 10W"
