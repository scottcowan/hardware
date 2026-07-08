# E-ink Tutor — Design Notes

Early stage. Requirements being gathered.

## Concept

A dedicated low-distraction learning device. Ask a question by voice, receive a written response on e-ink. Targeted at education contexts where battery life, readability, and focus matter more than a general-purpose screen.

## Design Goals

- **E-ink display** — sunlight readable, no backlight fatigue, days of battery life
- **STT input** — speak a question, get a written answer
- **Simple, single-purpose** — no general browsing, no notifications
- **Durable enclosure** — survives classroom/field use
- **Low power** — target >1 week standby, >8hr active use

## Open Questions

### Compute
- RP2040 + cloud STT/inference API? (lowest power, simplest)
- Pi Zero 2W? (can run Whisper tiny locally)
- ESP32-S3? (good WiFi/BLE, limited RAM)

### Display
- 7.5" e-ink (common, cheap, ~800×480) vs 10.3" (more readable, more expensive)
- Grayscale vs colour e-ink (colour has poor refresh, likely grayscale)
- Waveshare e-ink HATs are the most accessible option

### STT
- On-device: Whisper tiny on Pi Zero 2W (~150MB model, slow but offline)
- Cloud: Whisper API (fast, needs connectivity)
- Hybrid: local VAD to detect speech, cloud for transcription

### Connectivity
- WiFi for cloud inference
- BLE for phone pairing / config?
- Reticulum/LoRa — share mesh with cyberdeck for offline use?

### Target user
- Child learning at home?
- Adult language learner?
- Student with reading difficulties?
- This affects vocabulary, response length, and UI design

## Relationship to Cyberdeck

If both devices run Reticulum, the eink-tutor could route inference requests through the cyberdeck over LoRa mesh when no WiFi is available. The cyberdeck's local Llama 3B handles the inference, response is sent back over mesh.

## Next Steps

- [ ] Define target user more precisely
- [ ] Select compute platform
- [ ] Select e-ink display size and part
- [ ] Prototype STT pipeline on bench hardware
