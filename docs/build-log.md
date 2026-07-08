# Build Log

## 2026-07-07 — Project start

- Created repo
- Decided on Jetson Orin Nano 8GB as compute module (£220)
- Reference design: [CM Deck](https://github.com/sb-ocr/cmdeck) by sb-ocr
- Form factor: clamshell, 3D-printed enclosure
- Display: 12.3" ultrawide eDP, no touch (same footprint as CM Deck)
- Keyboard: Kailh Choc V1, QMK
- Power: 2× 21700 parallel → boost to 12V
- Cooling: 30mm PWM blower + rear vent slots (passive insufficient in sealed clamshell)
- Module compatibility: carrier PCB will support full Orin SO-DIMM family (Nano 4GB/8GB, NX 8GB/16GB)

## 2026-07-08 — Form factor locked, voice input research started

- Clamshell ultrawide confirmed, matching CM Deck 12.3" footprint
- No touchscreen — redundant on TUI machine, simplifies PCB and enclosure
- Active cooling confirmed — 30mm PWM blower exhausting through rear vents
- SO-DIMM carrier to be pin-compatible with all Orin modules (upgrade path to NX preserved)

- Voice input: early research recorded in `docs/research/voice-input.md`
  - MEMS mic (on-board): viable for carrier PCB v1
  - Throat mic (TENQ): bench validate before PCB commitment — connector incompatibility noted
  - Subvocalization (EMG): consumer market immature, deferred — no off-the-shelf models exist
  - PTT GPIO header: low-cost addition to v1 regardless of mic choice

### Next steps
- [ ] Source Jetson Orin Nano Developer Kit (£238, RS Components)
- [ ] Source Heltec LoRa32 v3 for bench RNode (~£15)
- [ ] Source TENQ throat mic + USB audio adapter for bench STT validation
- [ ] Identify 12.3" ultrawide eDP panel (no touch)
- [ ] Download Waveshare/Seeed Jetson Orin carrier reference schematics
- [ ] Begin carrier PCB schematic in KiCad
