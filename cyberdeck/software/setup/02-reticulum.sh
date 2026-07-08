#!/bin/bash
# Install Reticulum, NomadNet, and configure USB RNode (Heltec LoRa32 v3)

set -e

echo "==> Installing system dependencies"
sudo apt-get update
sudo apt-get install -y python3-pip python3-venv

echo "==> Installing Reticulum stack"
pip3 install rns
pip3 install nomadnet
pip3 install lxmf

echo "==> Detecting RNode (Heltec LoRa32 on /dev/ttyUSB0 or /dev/ttyACM0)"
RNODE_PORT=""
for port in /dev/ttyUSB0 /dev/ttyUSB1 /dev/ttyACM0 /dev/ttyACM1; do
  if [ -e "$port" ]; then
    RNODE_PORT="$port"
    echo "    Found device at $port"
    break
  fi
done

if [ -z "$RNODE_PORT" ]; then
  echo "    No RNode found — you can update ~/.config/reticulum/config manually"
  RNODE_PORT="/dev/ttyUSB0"
fi

echo "==> Adding user to dialout group (serial port access)"
sudo usermod -aG dialout "$USER"

echo "==> Writing Reticulum config"
mkdir -p ~/.config/reticulum
cat > ~/.config/reticulum/config <<EOF
[reticulum]
  enable_transport = true
  share_instance = yes
  shared_instance_port = 37428

[interfaces]

  [[RNode LoRa]]
    type = RNodeInterface
    interface_enabled = true
    port = $RNODE_PORT
    frequency = 868500000
    bandwidth = 125000
    txpower = 14
    spreadingfactor = 8
    codingrate = 5
    id_callsign = CYBERDECK
    id_interval = 600
EOF

echo "==> Creating rnsd systemd service"
sudo tee /etc/systemd/system/rnsd.service > /dev/null <<EOF
[Unit]
Description=Reticulum Network Stack Daemon
After=network.target

[Service]
Type=simple
User=$USER
ExecStart=$(which rnsd)
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable rnsd
sudo systemctl start rnsd

echo "==> Reticulum ready."
echo "    Start NomadNet TUI with: nomadnet"
echo "    Check status with:       rnstatus"
echo "    NOTE: log out and back in for dialout group to take effect"
