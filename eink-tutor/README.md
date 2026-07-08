# E-ink Tutor

Open-hardware educational device with an e-ink display and speech-to-text input. Designed for low-power, always-on use — long battery life, readable in any light, no backlight fatigue.

---

## Concept

A dedicated learning device: ask a question by voice, receive a clear written response on e-ink. Targeted at education contexts where screen fatigue, distraction, and battery life matter.

---

## Design Goals

- **E-ink display** — sunlight readable, no backlight fatigue, days of battery life
- **STT input** — speak a question, get a written answer
- **Local or cloud inference** — small local model for common queries, cloud for depth
- **Low power** — target >1 week standby, >8hr active use
- **Simple enclosure** — durable, single-purpose device

---

## Status

Early design — requirements being gathered.

### Open questions
- [ ] Display size and resolution (7.5" or 10.3" e-ink?)
- [ ] Compute platform (RP2040 + cloud API? Pi Zero 2W? ESP32-S3?)
- [ ] STT approach — on-device (Whisper tiny) vs cloud (Whisper API)
- [ ] Connectivity — WiFi only, or also BLE/LoRa?
- [ ] Target user — child, adult learner, language learner?
- [ ] Reticulum integration — share mesh with cyberdeck?

---

## Repository Structure

```
eink-tutor/
├── hardware/
│   └── pcb/        # KiCad PCB
├── firmware/       # MCU firmware
├── software/       # Application
├── docs/           # BOM, design notes, research
└── references/     # Datasheets
```
