# E-ink Tutor

Open-hardware AI educational device. Per-child, voice-in, e-ink display, offline-capable with WiFi sync.

A child asks a question by voice. The device transcribes it, routes to an AI tutor (Claude/GPT/Gemma via OpenAI-compatible API), and displays the response on a distraction-free e-ink screen. Follows a structured learning plan, adapts to the child's interests, downloads new content areas over WiFi.

---

## Hardware Overview

| Component | Detail |
|---|---|
| Compute | Raspberry Pi Zero 2W |
| Display | Waveshare 7.5" e-Paper HAT V2 — 800×480, 124 PPI, greyscale |
| Touch | GT911 capacitive overlay |
| Microphone | SPH0645LM4H I2S MEMS, 65dB SNR |
| Audio out | Piper TTS (offline neural TTS) → PAM8302 amp → 40mm speaker |
| Wake word | Porcupine (Picovoice) — <5% CPU |
| Battery | 4400mAh LiPo, ~2-3 day standby |
| Charging | USB-C, MCP73831 charger IC |
| Enclosure | 3D-printed, TPU bumper, child-safe |

**Per-device BOM: ~£138**

---

## Software Architecture

```
Device (Pi Zero 2W)
  ├── Local learning plan (SQLite + sqlite-vec semantic cache)
  ├── Porcupine wake word → Silero VAD
  ├── Audio → OpenAI-compatible server (STT + inference)
  ├── In-plan? → local content + server response
  ├── Off-plan new area? → queue for WiFi download
  ├── Piper TTS → speaker
  └── Session sync → parent dashboard on WiFi
```

### Server (OpenAI-compatible, not on device)
- STT: Whisper base
- Inference: Claude Sonnet / GPT / Gemma mix
- Per-child profiles, learning plans, parent dashboard

---

## Key Design Decisions

- **Greyscale e-ink** — better text contrast than colour options; Kaleido 3 actively degrades text
- **Pi Zero 2W over ESP32-S3** — local learning plan corpus requires filesystem + Python
- **Suspend-to-RAM** — 2s wake, image retained on e-ink; not hard power-off
- **Socratic interaction model** — questions before answers, hint ladder, no sycophancy
- **Per-child device identity** — no login; device MAC = child profile on server
- **Semantic cache** — 70-90% of in-plan queries answered without network round-trip
- **Offline-first for known content** — new topic areas download opportunistically

---

## Status

Early design — see [docs/design-notes.md](docs/design-notes.md) for full research-backed spec.

- [ ] PCB schematic
- [ ] Enclosure design
- [ ] Server software
- [ ] Device firmware / application
- [ ] First build
