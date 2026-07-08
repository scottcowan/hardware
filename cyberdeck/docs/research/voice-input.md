# Voice Input Research

Early-stage research. No decisions made — deferred until bench validation.

---

## Options Considered

### 1. Standard MEMS Microphone (on-board)
- ICS-43434 or SPH0645 I2S MEMS mic in enclosure bezel
- No peripherals, always available
- Works with Whisper small (CUDA) for full STT
- **Status: viable, carry on PCB constraints as optional**

### 2. Throat Microphone (TENQ walkie-talkie style)
- Product: TENQ Throat Mic with finger PTT, Yaesu 1-pin 3.5mm TS
- Captures throat vibration rather than open-air speech — closer to subvocal range
- **Connector issue:** Yaesu 1-pin is mono TS (radio impedance/levels), not standard TRRS headset. Cannot plug directly into a normal audio jack.
- **Workaround for bench:** USB audio adapter + TS→TRRS passive adapter (~£5). Validates the mic before any PCB commitment.
- **PTT button:** momentary switch in cable — useful as hardware push-to-transcribe wired to Jetson GPIO. Cleaner than VAD for quiet input.
- **Risk:** mic tuned for radio voice comms, not ML input. Whisper compatibility unvalidated.
- **Status: bench validate first, do not design PCB jack around this until confirmed**

### 3. Subvocalization via EMG (surface electromyography)
- Detects neuromuscular signals from throat/jaw during silent speech
- Reference: MIT AlterEgo (2018) — surface electrodes, custom trained classifier
- Hardware path: MyoWare 2.0 sensor boards (~$40 each, 4 needed) → ADS1115 ADC → Jetson GPIO/I2C
- ADC header can be added to carrier PCB as a passive feature (no cost if unpopulated)
- **Vocabulary limitation:** command-scale vocabulary (20–50 words) is realistic; free-form dictation is research-grade hard
- **Per-user training required:** model must be trained on individual's muscle signals
- **No consumer off-the-shelf trained models exist**
- **Status: early research, not on carrier PCB v1. Revisit after bench phase.**

---

## Consumer Subvocalization Landscape (as of 2026-07)

| Product | Status | Notes |
|---|---|---|
| MIT AlterEgo | Research only | Surface EMG, per-user trained, ~20-word vocab demonstrated |
| MyoWare 2.0 | Maker-ready | EMG sensor board, not a finished solution — requires custom ML |
| Meta CTRL-labs wristband | Acquired 2019 | Baked into Meta AR roadmap, not available standalone |
| UC San Diego ultrasound patch | Lab only | Ultrasound-based throat vibration, no timeline |
| Any trained open subvoc model | None | Essentially no off-the-shelf trained models exist |

**Verdict:** the consumer market has not caught up with the research. Command-vocabulary EMG is achievable as a DIY project; free-form subvocal dictation is not practical yet.

---

## Staged Implementation Plan

### Stage 1 — bench validation (do now)
- [ ] Buy TENQ throat mic (~£15) and USB audio adapter (~£5)
- [ ] Connect to dev kit via USB, test with `whisper.cpp` small model
- [ ] Test PTT button wired to Jetson GPIO as push-to-transcribe
- [ ] Record signal quality findings — does Whisper handle throat mic input cleanly?

### Stage 2 — carrier PCB v1 (if Stage 1 passes)
- TRRS or TS 3.5mm combo jack designed for validated mic impedance
- PTT GPIO header
- On-board MEMS mic as fallback (ICS-43434)

### Stage 3 — EMG (post bench phase, optional)
- MyoWare 2.0 × 4 + ADS1115 ADC
- ADC I2C header on carrier PCB v2 (passive, unpopulated on v1)
- Train command vocabulary classifier during extended bench use

---

## Notes
- Do not commit to a PCB jack design until Stage 1 is validated
- The PTT GPIO header costs nothing to add to v1 regardless of mic choice
- Subvocalization remains speculative for this build — treat as a future upgrade path
