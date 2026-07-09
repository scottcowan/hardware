# E-ink Tutor — Design Document

Research-backed design for an open-hardware AI educational device.
Last updated: 2026-07-09 — major revision: CM4 compute, dock station, Minecraft/building mode, server-side inference routing

---

## Concept

A dedicated per-child learning device. Portable e-ink tutor for reading and Q&A. Docks into a full workstation with monitor, keyboard, mouse for Minecraft, coding, and making. All inference runs on the house server — device is a thin client.

---

## Target User

- **Age:** 6+ (literacy assumed)
- **Use:** Unsupervised, per-child device
- **Subjects:** Broad syllabus following child's interests — including Minecraft, coding, making
- **Supervision:** Parental controls + session replay dashboard, no adult present during use
- **Quantity:** 6 devices

---

## Dual-Mode Design

```
Portable mode (e-ink, battery)          Docked mode (HDMI monitor, powered)
─────────────────────────────           ───────────────────────────────────
Reading, Q&A tutoring                   Minecraft Java → GeyserMC server
Voice interaction (wake word)           Scratch, Python, browser coding tools
E-ink display, Piper TTS                Full desktop (Labwc/Wayfire compositor)
Porcupine wake word                     Keyboard + mouse via dock USB-A
2-3 day battery (light use)             Powered from dock — no battery drain
```

The e-ink display stays active when docked — shows current challenge or tutor prompt as secondary display while Minecraft runs on the HDMI monitor.

---

## Architecture

```
Per-child device (CM4)
  ├── ESP32-S3 (always-on, ~25mA)
  │     ├── WakeNet9 wake word detection
  │     ├── Powers CM4 via TPS22918 load switch on wake word
  │     └── Returns to WakeNet after CM4 shuts down
  │
  └── CM4 (hard-off between portable sessions; always-on when docked+powered)
        ├── Local learning plan (SQLite + sqlite-vec semantic index)
        ├── Silero VAD → audio → house server (STT + inference)
        ├── In-plan? → serve from local content + server Llama 3B
        ├── Off-plan new area? → flag, queue content download on WiFi
        ├── Session log → parent dashboard (server-side, on WiFi sync)
        ├── E-ink display (7.5" 800×480) via SPI
        ├── Touch (GT911) + 5 physical buttons
        ├── Piper TTS → PAM8302 → speaker
        ├── HDMI → dock → monitor (docked mode)
        ├── USB-C alt mode → dock → keyboard + mouse
        └── Minecraft Java (PojavLauncher) → Pterodactyl GeyserMC server
```

---

## House Server Stack

```
House server
  ├── Ollama (Llama 3B) — routine Q&A inference, fast + free
  ├── cyberharness router — routes local vs cloud per request type
  ├── etutor-server — device API, profiles, content packages, dashboard
  ├── Pterodactyl — Minecraft server management
  │     └── Paper + GeyserMC — Java server, Bedrock iPad clients connect transparently
  └── Calibre-Web — per-child book libraries + recommendations
```

**Inference routing:**

| Request type | Model | Reason |
|---|---|---|
| Daily Q&A, hint ladder, in-session dialogue | Llama 3B (Ollama) | Conversational, fast, free |
| New content area generation | Cloud (Claude/GPT) | Depth + accuracy |
| Learning plan creation/update | Cloud | Structured reasoning |
| Book recommendations | Cloud | Cross-reference interest graph |
| Parent dashboard summaries | Cloud | Report generation |
| Interest graph inference | Llama 3B | Pattern matching |
| Building mode guidance | Llama 3B + guardrails | Routine making help |
| Dangerous/ambiguous building requests | Cloud + flag | Safety review |

Both cyberdeck and etutor devices are clients of the same cyberharness router. Cyberdeck additionally has local Llama 3B for offline/off-network use; etutor devices are always home-network-dependent.

---

## Hardware

### Compute: CM4 + ESP32-S3 co-processor

**CM4 (user has modules):**
- 4GB RAM — sufficient for Minecraft Java via PojavLauncher
- PCIe → M.2 NVMe for fast storage (Minecraft needs it)
- Native HDMI output → dock → monitor
- USB-C with alt mode → single-cable dock connection
- Gigabit Ethernet on carrier (fast server connection when docked)
- 2× Hirose DF40C-100DS-0.4V connectors on carrier PCB
- Full Wayland desktop when docked (Labwc or Wayfire)

**ESP32-S3 (WROOM-1) — always-on co-processor:**
- WakeNet9 wake word at ~25mA continuous
- Powers CM4 via TPS22918 load switch on wake word
- Graceful CM4 shutdown handshake via UART
- E-ink image retained during CM4-off (bistable)
- Plays audio boot cue via I2S while CM4 boots (~15-20s)

**Why CM4 over Pi Zero 2W:**
- Minecraft requires 4GB RAM — Zero 2W (512MB) cannot run it
- Native USB-C alt mode → clean single-cable dock
- You already have the modules
- Better desktop experience when docked
- Same carrier PCB approach as cyberdeck — proven pattern

### Display: Waveshare 7.5" e-Paper HAT V2
- 800×480, 124 PPI, greyscale
- SPI via CM4 carrier PCB
- GT911 capacitive touch overlay
- 18-24pt fonts adequate for ages 6+
- Partial refresh ~0.3s; A2 mode ~120ms
- DEEP_SLEEP after every refresh (2µA, image retained)
- Secondary display when docked — shows tutor prompt / current challenge

### Dock Station
- Single USB-C cable from device (alt mode: video + data + power)
- HDMI-A out → monitor
- 2× USB-A → keyboard + mouse
- USB-C PD in → charges device while docked
- PTN3460 DP→HDMI bridge on carrier PCB for alt mode
- 3D-printed cradle enclosure, passive USB-C breakout PCB
- **BOM: ~£18**

### Microphone: SPH0645LM4H (I2S MEMS)
- 65dB SNR
- 4-wire I2S → CM4 carrier
- On-board PCB mount in enclosure bezel

### Audio Output: Piper TTS + PAM8302
- Piper TTS offline neural TTS, ~150ms latency on CM4
- PAM8302 2.5W mono class D amp
- 40mm speaker in enclosure
- ESP32-S3 plays boot chime independently before CM4 is ready

### Physical Buttons
- **Power** — long press
- **Hold-to-speak** — alternative to wake word
- **Repeat** — replay last TTS response
- **Volume up / Volume down**

### Power
- **Cell:** 6000mAh LiPo pouch — ~2-3 days portable (CM4 heavier than Zero 2W)
- **Charging:** MCP73831 via USB-C, or from dock (pass-through PD)
- **Boost:** TPS61023 (3.7V → 5V) for CM4 rail
- **Load switch:** TPS22918 — inrush control mandatory for CM4
- **LDO:** AP2112K-3.3 for ESP32-S3 rail
- **Docked:** powered from dock, battery not used — unlimited session length

### Carrier PCB
- 4-layer (CM4 requires it — high-speed PCIe, USB 3.0)
- CM4 2× DF40C-100DS-0.4V connectors
- M.2 M-key NVMe slot
- PTN3460 DP alt mode bridge
- USB-C receptacle (alt mode + PD)
- HDMI-A for dock pass-through
- Gigabit Ethernet (RJ45)
- SPI for e-ink, I2C for GT911 touch
- SPH0645 I2S mic, PAM8302 I2S amp
- ESP32-S3 WROOM-1, TPS22918, TPS61023, MCP73831
- 5× tactile buttons
- JLCPCB fabrication — reference: Waveshare CM4 carrier open schematics

---

## Minecraft / Building Mode

### Server Setup (Pterodactyl)
- Paper + GeyserMC on Pterodactyl — iPad Bedrock clients and CM4 Java clients connect to same server
- ComputerCraft mod — Lua programmable turtles, strongest coding hook for this age
- ComputerCraft web IDE plugin — child writes Lua in browser (iPad Safari or device browser), turtle executes in-game
- etutor-server ↔ Minecraft via:
  - Pterodactyl REST API (server start/stop, status)
  - RCON (in-game commands — give items, teleport, set time)
  - Paper plugin webhook (build completions → POST to etutor-server)

### Educational Challenge System
- AI acts as dungeon master — sets build challenges tied to curriculum topic
- Challenge delivered as NPC dialogue or in-game chat
- On challenge completion: plugin POSTs event → etutor-server logs achievement, updates mastery, generates next challenge
- Examples by subject:

| Subject | Challenge |
|---|---|
| Maths | Build a structure using exactly 144 blocks (12²) |
| Geography | Recreate your town's layout from a map |
| History | Build a Roman arch — what makes it strong? |
| Physics | Build a redstone circuit that turns a light on and off |
| Programming | Write a ComputerCraft turtle program to build a wall |
| Biology | Build a cross-section of a plant cell at 1:10 scale |

### Building Mode Guardrails

Separate guardrail profile from tutoring mode — building is child-led so off-topic surface area is larger:

| Request type | Response |
|---|---|
| Normal making/building help | Full assistance, age-appropriate complexity |
| Dangerous physical instructions (explosives, weapons) | Hard block — "I can't help with that, but let's build X instead" |
| Physically risky but normal (fire, electricity) | Assist + "ask an adult before trying this for real" |
| Minecraft-specific violence/grief | Gentle redirect — "on this server we build, not destroy" |
| Roblox | Redirect to Minecraft — Roblox not supported (safety/content reasons) |
| Scope too advanced for age | Scale down — "let's start with a smaller version" |
| Off-topic entirely | Gentle focus — "let's finish what we started, then we can explore that" |

Parent dashboard flags all hard blocks and redirects. Child never sees a lecture.

### Minecraft vs Roblox Decision
- **Roblox: excluded** — platform-curated content, social features with strangers, monetisation-driven, can't fully control what children access
- **Minecraft: preferred** — server owner controls all content, no external social, educational precedent (Minecraft Education Edition), offline-capable, ComputerCraft for real programming

---

## Inference Routing: Server-Side Only

**The device has no local inference.** All models run on the house server:

- Routine Q&A → Llama 3B on Ollama (fast, free, runs locally)
- Content generation → Cloud API (Claude Sonnet / GPT / Gemma)
- etutor-server points `INFERENCE_MODEL` at cyberharness OpenAI-compatible endpoint
- cyberharness decides local vs cloud — etutor-server doesn't need to know

This applies to both tutoring mode and building/Minecraft mode. The guardrail system prompt is just a different system prompt routed through the same infrastructure.

---

## Content Architecture

### Learning Plan
- Structured per-child plan stored as SQLite + sqlite-vec on device
- In-plan queries served from local cache + Llama 3B on server
- Off-plan: flag → queue → download on WiFi connect
- Minecraft challenges are part of the learning plan — build challenges tied to curriculum topic

### Calibre-Web Integration
- Per-child accounts on house Calibre-Web instance
- AI cross-references current reading with tutoring topics
- "You know how the book talked about gravity? That's actually why Minecraft has a fall damage mechanic..."
- Recommendation engine matches interest graph to library

---

## Bill of Materials (Revised — CM4 + Dock)

| Item | Part | Est. Price |
|---|---|---|
| Compute | CM4 4GB (have modules) | £0 |
| CM4 connectors | 2× Hirose DF40C-100DS-0.4V | £4 |
| Display | Waveshare 7.5" e-Paper HAT V2 | £45 |
| Touch overlay | GT911 capacitive overlay | £18 |
| NVMe SSD | 256GB M.2 2280 | £25 |
| Co-processor | ESP32-S3 WROOM-1 | £3 |
| Microphone | SPH0645LM4H | £3 |
| TTS amp | PAM8302 | £1 |
| Speaker | 40mm 4Ω 3W | £3 |
| Physical buttons | 5× tactile + caps | £3 |
| Battery | 6000mAh LiPo pouch | £22 |
| Charger IC | MCP73831 | £1 |
| Boost converter | TPS61023 | £2 |
| Load switch | TPS22918 | £1 |
| LDO | AP2112K-3.3 | £1 |
| DP alt mode bridge | PTN3460 | £3 |
| USB-C receptacle | Alt mode + PD | £2 |
| PCB fabrication | 4-layer, JLCPCB, 10 off | £35 |
| PCB components | Passives, connectors, headers | £15 |
| Enclosure | 3D-printed TPU bumper + PLA shell | £10 |
| Misc | — | £5 |
| **Device subtotal** | | **~£202** |
| **Dock** | Cradle + USB-C breakout + HDMI + USB-A | **~£18** |
| **Per-device total** | | **~£220** |

**6 devices total: ~£1,320**
Working budget: **~£230 per device** with contingency.

---

## Decisions Made

- **Compute:** CM4 (modules already owned) — enables Minecraft, proper dock, 4GB RAM
- **Battery:** 6000mAh, ~2-3 days portable, unlimited docked
- **Input:** Touch (GT911) + 5 physical buttons + keyboard/mouse when docked
- **Quantity:** 6 devices
- **Minecraft:** Java via PojavLauncher → GeyserMC server (iPad Bedrock kids on same server)
- **Roblox:** Excluded — Minecraft only
- **Inference:** Server-side only (Llama 3B for routine, Cloud for generation)
- **Building guardrails:** Separate profile, harder limits than tutoring mode
- **Dock:** Single USB-C cable, HDMI + USB-A out, PD charging in

## Open Questions

- [ ] CM4 Lite (no WiFi) vs CM4 standard — Lite needs external WiFi module (~£8), standard has it onboard
- [ ] ComputerCraft web IDE — which plugin? or browser-based coding environment?
- [ ] Wake word — "Hey Tutor"? Custom Porcupine training needed
- [ ] Boot audio cue — what does ESP32-S3 play during CM4 boot?
- [ ] Enclosure drop-resistance — TPU bumper or Mobius plastic panel?
- [ ] Speaker placement — front vs side-firing?
- [ ] Minecraft challenge difficulty calibration — auto-grade by age or manual parent config?

---

## Research Sources

- 2026-07-08 parallel research agents: display, compute, STT, educational landscape, power, Reticulum
- 2026-07-08 deep research (109 agents, 17 verified claims): interleaving d=1.05, retrieval practice, metacognitive development trajectory, dialogic reading β=0.51, cognitive load reversal effect
- Khan Academy Kids analysis: read-aloud, mastery pacing, session length, anti-sycophancy
