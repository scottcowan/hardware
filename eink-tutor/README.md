# E-ink Tutor

Open-hardware AI educational device. Per-child, voice-in, e-ink display, dockable workstation.

Portable: Kindle-like e-ink tutor for reading, Q&A, and voice interaction.
Docked: Full child workstation — Minecraft, Scratch, Python, coding tools.

---

## Hardware Overview

| Component | Detail |
|---|---|
| Compute | CM4 4GB |
| Display | Waveshare 7.5" e-Paper HAT V2 — 800×480, 124 PPI, greyscale |
| Touch | GT911 capacitive overlay |
| Co-processor | ESP32-S3 WROOM-1 — always-on WakeNet9 wake word |
| Microphone | SPH0645LM4H I2S MEMS, 65dB SNR |
| Audio out | Piper TTS (offline) → PAM8302 → 40mm speaker |
| Storage | 256GB NVMe M.2 |
| Battery | 6000mAh LiPo, ~2-3 day portable, unlimited docked |
| Charging | USB-C, MCP73831 |
| Dock | Single USB-C → HDMI monitor + keyboard + mouse + charging |
| Minecraft | Java via PojavLauncher → GeyserMC (same server as iPad Bedrock) |

**Per-device BOM: ~£220 (CM4 modules already owned)**
**6 devices: ~£1,320**

---

## Software Architecture

```
Device (CM4)
  ├── Local learning plan (SQLite + sqlite-vec)
  ├── ESP32-S3: WakeNet9 → powers CM4 → handles boot cue
  ├── Audio → etutor-server → cyberharness router
  │     ├── Routine Q&A → Llama 3B (Ollama, house server)
  │     └── Content/plan generation → Cloud API
  ├── E-ink + Piper TTS output
  ├── Docked: Minecraft Java → GeyserMC server
  └── WiFi sync → session logs, content packages, book recommendations
```

## House Server Stack

- **Ollama** — Llama 3B for routine inference
- **cyberharness** — local/cloud routing
- **etutor-server** — device API, profiles, dashboard, Calibre-Web integration
- **Pterodactyl** — Minecraft server management
- **Paper + GeyserMC** — Java server, iPad Bedrock + CM4 Java clients both connect
- **Calibre-Web** — per-child book libraries

---

## Modes

### Portable (e-ink, battery)
- Voice Q&A tutoring
- Reading via Calibre-Web books
- Socratic AI tutor — Llama 3B for daily sessions, Cloud for new content
- 2-3 day battery

### Docked (HDMI, powered)
- Minecraft Java → educational challenges on Pterodactyl server
- ComputerCraft Lua programming in-game
- Full Wayland desktop
- E-ink stays active as secondary display showing current challenge

---

## Key Design Decisions

- **CM4 not Pi Zero 2W** — Minecraft needs 4GB RAM; dock needs native USB-C alt mode
- **Roblox excluded** — Minecraft only (content control, no strangers, ComputerCraft)
- **Server-side inference only** — device is thin client; no local AI on device
- **Llama 3B for routine, Cloud for generation** — cost-efficient routing via cyberharness
- **Building mode has harder guardrails** — child-led making has wider off-topic surface area
- **ESP32-S3 co-processor** — CM4 hard-off between portable sessions; instant wake word response

---

## Status

Early design — see [docs/design-notes.md](docs/design-notes.md) for full spec.

- [ ] CM4 carrier PCB schematic (4-layer)
- [ ] Dock PCB/enclosure
- [ ] etutor-server Pterodactyl + Minecraft integration
- [ ] ComputerCraft challenge system
- [ ] Building mode guardrails system prompt
- [ ] Enclosure design
- [ ] First build
