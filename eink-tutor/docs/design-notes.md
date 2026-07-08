# E-ink Tutor — Design Document

Research-backed design for an open-hardware AI educational device.
Last updated: 2026-07-08

---

## Concept

A dedicated per-child learning device. Child asks questions by voice, receives written responses on e-ink. Follows a structured learning plan, adapts within it, downloads new content areas opportunistically over WiFi. Gentle, focused, distraction-free.

---

## Target User

- **Age:** 6+ (literacy assumed)
- **Use:** Unsupervised, per-child device
- **Subjects:** Broad syllabus following child's interests, relating to personal examples
- **Supervision:** Parental controls + session replay dashboard, no adult present during use

---

## Architecture

```
Per-child device (Pi Zero 2W)
  ├── Local learning plan (SQLite + sqlite-vec semantic index)
  ├── Porcupine wake word → Silero VAD
  ├── Audio → OpenAI-compatible server (STT + inference)
  ├── In-plan? → serve from local content + server inference
  ├── Off-plan new area? → flag, queue content download on WiFi
  ├── Session log → parent dashboard (server-side, on WiFi sync)
  ├── E-ink display (7.5" 800×480)
  └── Piper TTS → speaker (PAM8302 amp)
```

### Server (OpenAI-compatible, not on device)
- STT: Whisper base (or OpenAI Whisper API)
- Inference: Claude Sonnet / GPT / Gemma 4:12B mix
- Per-child profiles: interests, reading level, mastery state, session history
- Learning plan generation and content package creation
- Parent dashboard API

---

## Hardware

### Compute: Raspberry Pi Zero 2W
- Chosen over ESP32-S3 because device must hold and reason over a local learning plan corpus
- Suspend-to-RAM between sessions (~2s wake, ~60-80mA suspend) — not hard off
- DietPi image for fast boot and reduced idle power
- Python development — fastest iteration for evolving educational content logic
- Proven reference: wyoming-satellite (Pi Zero 2W + mic → WiFi → remote STT)

### Display: Waveshare 7.5" HAT V2
- 800×480, 124 PPI, greyscale (B/W + 4 grey levels)
- SPI HAT — plugs directly onto Pi Zero 2W 40-pin header, zero wiring
- Greyscale chosen over colour — better contrast for text, no refresh penalty
- Colour e-ink (Kaleido 3) actively worse for reading text — grey cast, lower PPI
- 18-24pt fonts at 124 PPI: adequate for ages 6+
- Partial refresh: ~0.3s per GDEY075T7 spec; A2 fast mode feasible with custom LUTs
- Physical dimensions: 170×111mm bare panel, ~280-350g finished device
- **Touch:** GT911 capacitive overlay (~£15-20 on AliExpress) over glass for navigation

### Microphone: SPH0645LM4H (I2S MEMS)
- 65dB SNR — meaningfully better than INMP441 for noisy environments
- 4-wire I2S: BCLK/LRCLK/DATA → Pi GPIO 18/19/20
- On-board PCB mount in enclosure bezel

### Audio Output: Piper TTS + PAM8302 amp
- Piper TTS — offline neural TTS, runs on Pi Zero 2W, ~150ms latency
- PAM8302 — 2.5W mono class D amp, I2S input, tiny package
- Small 40mm speaker in enclosure

### Wake Word: Porcupine (Picovoice)
- Official Pi Zero 2W support confirmed
- <5% CPU on single Cortex-A core
- Multi-language support (important for non-English families)
- Free tier for prototype; paid for production

### VAD: Silero VAD
- 2MB ONNX model, <1ms per 30ms frame
- Better than WebRTC VAD for children's hesitant speech patterns
- End-of-speech: trigger after 600-800ms silence

### Power
- **Cell:** 4400mAh LiPo pouch (Adafruit 1578 or equivalent) — ~2-3 day standby
- **Charging:** MCP73831 (custom PCB) or TP4056+DW01A module (prototype) via USB-C
- **Boost:** TPS61023 (3.7V → 5V, 94% efficiency) for Pi rail
- **Load switch:** TPS22918 for Pi 5V (inrush control — mandatory, Pi has large input caps)
- **LDO:** AP2112K-3.3 for logic rail
- **Sleep strategy:** Pi suspend-to-RAM (~60-80mA), e-ink DEEP_SLEEP command after every refresh (2µA, image retained), Porcupine always-on on Pi (~5% CPU)

### PCB
- Custom carrier: Pi Zero 2W header, SPH0645 I2S mic, GT911 touch I2C, PAM8302 I2S amp, MCP73831 charger, TPS61023 boost, USB-C input, battery connector, speaker connector
- 2-layer, JLCPCB fabrication

---

## Content Architecture

### Learning Plan
- Structured per-child plan: topics, progression, vocabulary, example prompts
- Stored as SQLite + sqlite-vec semantic index on device
- Device can flex within plan: answer in-plan questions, adapt pacing, vary examples
- Semantic search determines "is this in-plan?" (cosine similarity >0.85 threshold)

### Off-Plan Handling
- Out-of-plan question detected → gentle redirect in current session
- New topic area flagged → queued for download
- On WiFi connect: server generates content package for new area → syncs to device SQLite
- Content packages: small structured JSON/markdown, tagged by topic, age-level, reading level

### Offline Capability
- In-plan queries: fully offline from local SQLite + semantic cache
- Off-plan queries: server required; device shows "I'll find out more about that" message
- Piper TTS: fully offline
- Wake word detection: fully offline

---

## Software Design

### Interaction Model
- **Socratic tutoring** — lead with questions, require verbal answer, never accept silence as understanding
- **Response length:** max 2-3 sentences for ages 6-8, short paragraph for 9+
- **Hint ladder:** nudge → hint → explain (3 levels before moving on)
- **Gentle redirect** for off-topic/inappropriate — acknowledge, steer back naturally
- **No sycophancy** — "Interesting!" not "Amazing answer!"

### Interest Graph
- **Onboarding:** Touch screen + pictograms (first session) — child selects interests visually
- **Ongoing:** Passive inference from conversation topics — server builds interest graph
- **Age-group trends:** Server incorporates what similar-age children find engaging as signal
- Interest graph shapes example selection and topic connections server-side

### Session Continuity
- **Session start:** Device zooms out — "What shall we explore today?" with 2-3 suggested areas based on recent sessions and interest graph
- **Within-session:** Proactive continuity — "Last time we were talking about volcanoes — did you know they also exist on other planets?"
- **Cross-session memory:** Server maintains state; device syncs on WiFi connect

### Parental Dashboard (server-side)
- Session replay: full conversation transcript
- Learning summary: topics covered, questions asked, apparent sticking points
- Interest graph visualisation
- Reading level progression
- Time spent per session/week
- Flagged items (off-plan requests, redirect events)

### Per-Child Profile
- Device identity = child profile (no login needed)
- Server maps device MAC/ID → child name, age, interests, mastery, reading level
- Parent sets up profile on server before first use; device onboarding collects interests

---

## Bill of Materials (Preliminary)

| Item | Part | Est. Price |
|---|---|---|
| Compute | Raspberry Pi Zero 2W | £15 |
| Display | Waveshare 7.5" e-Paper HAT V2 | £45 |
| Touch overlay | GT911 capacitive overlay + controller | £18 |
| Microphone | SPH0645LM4H breakout or bare IC | £3 |
| TTS amp | PAM8302 | £1 |
| Speaker | 40mm 4Ω 3W | £3 |
| Battery | 4400mAh LiPo pouch | £18 |
| Charger IC | MCP73831 (or TP4056 module) | £1 |
| Boost converter | TPS61023 | £2 |
| Load switch | TPS22918 | £1 |
| PCB fabrication | 2-layer, JLCPCB, 5 off | £8 |
| PCB components | Passives, connectors, headers | £8 |
| Enclosure | 3D-printed TPU bumper + PLA shell | £10 |
| USB-C port, misc | — | £5 |
| **Total per device** | | **~£138** |

Working budget: **~£150 per device** with contingency.

---

## Open Questions

- [ ] Charging cadence — nightly USB-C (phone-like) or multi-day (Kindle-like)?
- [ ] Physical buttons — power only, or also volume/repeat?
- [ ] Touch panel vs physical buttons for navigation (touch adds GT911 + overlay complexity)
- [ ] Enclosure drop-resistance — TPU bumper sufficient, or need Mobius plastic panel (~£130 premium)?
- [ ] Speaker placement — front-facing vs side-firing in enclosure?
- [ ] Piper TTS voice selection — child-friendly voice, language options?

---

## Research Sources

All findings from parallel research agents, 2026-07-08:

- **Educational landscape:** ITS effect size d=0.66 (50 studies); OLPC lesson: hardware alone doesn't teach; Moxie $1500 = current AI education hardware ceiling; white space confirmed
- **STT:** Whisper API $0.006/min; Porcupine on Pi Zero 2W confirmed; Silero VAD superior for children's speech; wyoming-satellite = reference architecture
- **Display:** Greyscale > Kaleido 3 for text; 7.5" 800×480 124PPI adequate at 18-24pt; partial refresh ~0.3s; A2 mode ~120ms for token-by-token streaming
- **Compute:** Pi Zero 2W recommended for local content corpus; HeyWillow proves ESP32-S3 architecture; suspend-to-RAM 2s wake preferred over hard-off
- **Power:** Pi Zero 2W suspend ~60-80mA; e-ink DEEP_SLEEP 2µA; 4400mAh = 2-3 day standby; MCP73831 for charging; TPS22918 inrush control mandatory
- **Reticulum:** LoRa viable as fallback (650ms at SF7) but WiFi primary; semantic cache handles 70-90% of in-plan queries offline
