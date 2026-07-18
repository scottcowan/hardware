# systemd — Quick Reference & Troubleshooting

## Essential commands

```bash
# Service management
systemctl status <service>           # check status + recent logs
systemctl start/stop/restart <svc>   # control service
systemctl enable/disable <svc>       # autostart on boot
systemctl reload <svc>               # reload config without restart

# User services (rnsd, cyberdeck-voice, etc.)
systemctl --user status <service>
systemctl --user enable --now <svc>  # enable and start immediately

# Logs
journalctl -u <service>              # all logs for service
journalctl -u <service> -f           # follow live
journalctl -u <service> --since "1 hour ago"
journalctl -b                        # logs since last boot
journalctl -b -1                     # logs from previous boot (useful post-crash)

# Boot analysis
systemd-analyze blame                # slowest services at boot
systemd-analyze critical-chain       # critical path
```

## Common Failures

### Service fails to start — "Failed to connect to bus"

**Cause:** User service run as wrong user, or D-Bus not available.

**Fix:**
```bash
# Check the service user:
systemctl cat <service> | grep User
# Run as correct user, or remove User= line for system services
```

---

### Service keeps restarting (crash loop)

**Diagnosis:**
```bash
journalctl -u <service> -n 50       # last 50 lines
systemctl status <service>           # shows exit code
```

**Common causes:**
- Missing dependency (file, port, another service)
- Permission error on a file/socket
- Environment variable not set

---

### "Unit not found" for user service

**Cause:** Service file not in the right location.

**User service files go in:** `~/.config/systemd/user/`
**System service files go in:** `/etc/systemd/system/`

After adding:
```bash
systemctl --user daemon-reload   # reload unit files
systemctl daemon-reload          # for system services
```

## Cyberdeck services

```bash
systemctl status ollama                        # Ollama inference server
systemctl --user status rnsd                   # Reticulum daemon
systemctl --user status cyberdeck-voice        # wake word listener
```
