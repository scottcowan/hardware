# Design Conversation — 2026-07-07

Initial design session covering hardware selection, architecture decisions, and software stack for the Jetson Cyberdeck project.

---

## Hardware Decisions

### Compute Module: Jetson Orin Nano 8GB
- Part: 900-13767-0030-000
- £220 bare module, £238 via RS Components as developer kit (recommended)
- Dev kit includes carrier board, 65W USB-C PSU, and the 8GB module
- 6× ARM A78AE @ 1.5GHz, 1024-core Ampere GPU, 40 TOPS, 8GB LPDDR5 shared

**Rejected alternatives:**
- NVIDIA Tesla V100 SXM2 — SXM2 is a server NVLink socket, not PCIe, requires DGX baseboard. 300W TDP. Dead end.
- Jetson Orin NX 16GB (£660) — same A78AE CPU architecture, marginal performance gain, not worth £440 premium
- CM5 + Hailo-8 HAT — better desktop experience but locked to Hailo model zoo, cannot run arbitrary HuggingFace models
- CM5 + M.2 → PCIe mobile GPU — CM5 M.2 is PCIe Gen 2 ×1, no CUDA drivers for ARM Linux outside Jetson, insufficient power

### Dev Kit First
- Order the Jetson Orin Nano Developer Kit (£238 RS Components: https://uk.rs-online.com/web/p/processor-development-tools/2647384)
- Validate full software stack before designing carrier PCB
- Bare module purchase deferred until carrier PCB design is ready

### Display
- eDP panel, 10–12", 1920×1200 IPS, ~300 nit
- **No touchscreen** — redundant on a TUI machine, removes digitizer IC and FPC from carrier PCB

### Form Factor
- Clamshell, inspired by [CM Deck](https://github.com/sb-ocr/cmdeck)
- McMaster friction hinges
- 3D-printed enclosure
- Kailh Choc V1 keyboard, QMK firmware
- Cirque 40mm trackpad retained

### Mesh Radio: Reticulum RNode
- SX1276 LoRa at 868MHz (EU ISM band, 25mW, licence-free)
- RP2040 MCU running RNode firmware, presents as USB serial to Jetson
- On-board carrier PCB integration planned for final build
- Bench phase: Heltec LoRa32 v3 (~£15) flashed with RNode firmware via USB
- Software: `rnsd` daemon, NomadNet TUI, rnsh (encrypted remote shell over mesh)

---

## Desktop / GPU Tradeoffs

### Why Jetson GPU is fine for this build
- Primary concern flagged: Ampere GPU is poor at desktop compositing and has no hardware video decode
- **Video decode: non-issue** — user doesn't need it
- **Compositing: non-issue** — user runs TUI only (tmux, Neovim, oterm, nomadnet)
- TUI on a terminal emulator uses almost no GPU — effectively framebuffer + text
- Lightweight WM (Sway/Wayfire) or no WM at all

### Why bigger Jetson modules don't help
- All Orin modules use A78AE cores — more cores and higher clocks, but same architecture
- Desktop feel is architectural, not fixable by spending more
- 40 TOPS on Nano 8GB is sufficient for Llama 3.2 3B real-time, 7B quantized usably

---

## Software Stack

### AI Inference
- Ollama — single install, runs on JetPack out of the box
- Primary model: `llama3.2:3b-instruct-q4_K_M` — fast, fits in 8GB shared RAM
- Also: `nomic-embed-text` for local RAG

### TUI Stack
- tmux (session management, cyberdeck status bar)
- Neovim (AppImage — JetPack apt version too old)
- oterm (Ollama TUI frontend), alias: `ai`
- llm CLI + llm-ollama plugin
- NomadNet (Reticulum TUI), alias: `mesh`
- btop / jtop (system monitoring)

### Jetson Tweaks
- GUI desktop disabled (`multi-user.target`)
- Default 10W power mode, `maxperf` alias for heavy inference
- `jtop` for GPU/CPU/memory/power monitoring

### Setup Scripts
All in `software/setup/`:
- `00-run-all.sh` — single command first boot
- `01-ollama.sh` — Ollama + model pulls
- `02-reticulum.sh` — Reticulum stack, RNode config, rnsd systemd service
- `03-tui-stack.sh` — tmux, Neovim, oterm, llm CLI, aliases
- `04-jetson-tweaks.sh` — power modes, jtop, disable GUI

---

## Harness Architecture (cyberharness — TBD repo)

### Concept
The Jetson runs a full harness runtime with connectivity-aware model routing. It is not a thin client — it owns the full GSD workflow and routes phases to local or cloud inference based on connectivity and phase requirements.

### Routing Logic
```
is_connected()
  → true  : Claude API (fast, full tool use)
  → false : local Ollama (discuss-only phases)

phase_requires_cloud(phase)
  → discuss, spec, explore : local ok
  → plan, execute, verify  : queue until connected
```

### Offline Queue
- Harness completes discuss/spec phases locally
- Writes context docs to `~/.cyberdeck/queue/` as JSON envelopes
- On reconnect, queue drains automatically → Claude API
- Queue survives reboots, inspectable with `ls`

### Connectivity
- WiFi primary
- Reticulum/LoRa mesh secondary — `rnsh` gives encrypted shell to home server over LoRa without internet

### Phase Routing
| Phase | Model | Reason |
|---|---|---|
| discuss | Local Llama 3B | Conversational, low stakes on speed |
| spec | Local Llama 3B | Clarifying questions, ambiguity scoring |
| explore / ideation | Local Llama 3B | Works offline |
| plan | Cloud Claude | Needs tool use, web research, pattern mapping |
| execute | Cloud Claude | Code generation, file writes, atomic commits |
| verify | Cloud Claude | Goal-backward analysis |

### Implementation Components
| Component | Effort | Notes |
|---|---|---|
| Connectivity probe | Trivial | ping / DNS check on interval |
| Model router | Small | Swap Ollama vs Claude API base URL + model name |
| Queue manager | Medium | Write/read JSON envelopes, drain on reconnect |
| GSD phase hooks | Medium | Insert router at model call layer |
| Streaming display | Small | Pipe Claude API stream to terminal |

Both Ollama and Claude API are OpenAI-compatible — router is primarily a base URL + model name swap.

### Open Questions
- Server-side harness: Claude Code + GSD, or custom? (TBD)
- Handoff: handled by harness automatically once connected
- When connected: fast inference via Claude API, results stream back locally

---

## Next Steps
1. Order Jetson Orin Nano Developer Kit (£238, RS Components)
2. Order Heltec LoRa32 v3 (~£15) for bench RNode
3. Flash JetPack, run `software/setup/00-run-all.sh`
4. Validate Ollama + Reticulum on bench
5. Measure real power draw under inference load
6. Begin carrier PCB schematic (KiCad, based on Waveshare Jetson carrier reference)
7. Spec cyberharness repo
