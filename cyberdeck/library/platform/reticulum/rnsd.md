# rnsd — Reticulum Network Stack Daemon

## Quick Reference

```bash
rnsd                    # start daemon (foreground)
rnsd -d                 # debug output
rnstatus                # show interface status
rnstatus --json         # JSON output (used by machine context injection)
rnid                    # show your Reticulum identity hash
rnpath <dest_hash>      # find path to destination
```

## Config location

`~/.config/reticulum/config` — written by `02-reticulum.sh`

## Common Failures

### RNode not appearing / rnsd can't open serial port

**Symptom:** `rnsd` starts but shows no RNode interface, or
`Permission denied: /dev/ttyACM0`.

**Fix:**
```bash
sudo usermod -aG dialout $USER   # add to dialout group
# Log out and back in, then:
ls -la /dev/ttyACM0              # should show dialout group
systemctl --user restart rnsd
```

---

### Interface shows but no links established

**Symptom:** `rnstatus` shows interface but 0 links, no incoming packets.

**Cause A:** Antenna not connected or poor connection.

**Cause B:** Frequency mismatch with other nodes. Check all nodes use
same frequency (default 868.5MHz EU):
```bash
# In ~/.config/reticulum/config:
frequency = 868500000
bandwidth = 125000
spreadingfactor = 8
```

**Cause C:** Duty cycle limit hit (EU 868MHz 1% limit). Wait 60s.

---

### rnsd crashes on start

**Symptom:** `rnsd` exits immediately with traceback.

**Cause:** Config file syntax error. Validate:
```bash
python3 -c "import configparser; c = configparser.ConfigParser(); c.read('~/.config/reticulum/config'); print('OK')"
```

---

### NomadNet can't find destinations

**Symptom:** NomadNet shows no nodes in directory.

**Cause:** rnsd not running, or shared instance not enabled.

**Fix:**
```bash
systemctl --user status rnsd     # check daemon is running
# In config: share_instance = yes (already set by 02-reticulum.sh)
```

## Systemd service

```bash
systemctl --user enable rnsd     # enable on login
systemctl --user start rnsd      # start now
systemctl --user status rnsd     # check status
journalctl --user -u rnsd -f     # follow logs
```

## Config reference (868MHz EU, RNode)

```ini
[reticulum]
  enable_transport = true
  share_instance = yes
  shared_instance_port = 37428

[interfaces]
  [[RNode LoRa]]
    type = RNodeInterface
    interface_enabled = true
    port = /dev/ttyACM0
    frequency = 868500000
    bandwidth = 125000
    txpower = 14
    spreadingfactor = 8
    codingrate = 5
    id_callsign = CYBERDECK
    id_interval = 600
```
