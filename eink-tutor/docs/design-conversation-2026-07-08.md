# Design Conversation — 2026-07-08 / 2026-07-09

Second design session covering eink-tutor evolution: CM4 compute, dock station, Minecraft integration, building mode, inference routing, and server stack.

---

## Key Decisions

### Compute: CM4 (replaces Pi Zero 2W)
- Minecraft Java via PojavLauncher requires 4GB RAM — Zero 2W (512MB) cannot run it
- CM4 native USB-C alt mode → clean single-cable dock (Zero 2W needs extra ICs, still messy)
- User has CM4 modules — no additional cost
- Carrier PCB uses 2× Hirose DF40C-100DS-0.4V (same approach as cyberdeck SO-DIMM)
- 4-layer PCB required (PCIe for NVMe, USB-C alt mode)

### Dock Station
- Single USB-C cable: video (DP alt mode via PTN3460) + USB 2.0 data + PD charging
- Dock breaks out to: HDMI-A → monitor, 2× USB-A → keyboard + mouse, USB-C PD in
- 3D-printed cradle + passive USB-C breakout PCB
- ~£18 BOM per dock
- E-ink display stays active when docked — secondary display for tutor prompts

### Minecraft / Building Mode
- Roblox excluded: platform content, strangers, monetisation, no control
- Minecraft Java via PojavLauncher on CM4 → user's Pterodactyl GeyserMC server
- iPad Bedrock clients and CM4 Java clients connect to same server transparently
- ComputerCraft mod — Lua programmable turtles, best coding hook for ages 6-12
- ComputerCraft web IDE — child writes code in browser, turtle executes in-game (works on iPad too)
- etutor-server integrates with Pterodactyl API + RCON + Paper plugin webhooks
- AI acts as dungeon master: sets curriculum-linked build challenges, awards completions, generates next challenge

### Building Mode Guardrails
- Separate, harder guardrail profile from tutoring mode
- Child-led making has much wider off-topic surface area than AI-led tutoring
- Hard block: dangerous physical instructions (no exceptions)
- Soft redirect: risky-but-normal activities ("ask an adult for the real version")
- Scope cap: age-appropriate complexity ceiling
- All blocks/redirects flagged to parent dashboard
- No lectures to child — redirect is natural, not punitive

### Inference Routing
- Server-side only — device has no local AI
- cyberharness router on house server handles all routing decisions
- etutor-server is a client of cyberharness (OpenAI-compatible endpoint)
- Routine Q&A → Llama 3B on Ollama (fast, free)
- Content generation / learning plan → Cloud (Claude/GPT)
- Same routing infrastructure as cyberdeck — both devices are house server clients
- Cyberdeck additionally has local Llama 3B for off-network use; etutor is always home-bound

### Khan Academy Kids Analysis
- Read-aloud everything — even for literate 6-year-olds, TTS reinforces phonics
- Short sessions with clear endings — suggest break after 15-20 min
- Celebration without sycophancy — audio chime, not "Amazing answer!"
- Curriculum sequencing reference — K-8 topic ordering is well-researched, use as loose reference
- Key differentiator: KAK can't follow specific interests or handle open-ended questions; eTutor can

### Peer-Reviewed Research Findings (adversarially verified, 109 agents)
- **Interleaving beats blocking:** d=1.05 in maths (Rohrer 2014) — AI must enforce, children self-select wrong
- **Retrieval practice:** reliably beats restudying ages 6-10 (Karpicke 2016); feedback is active ingredient
- **Metacognitive control:** doesn't emerge until ages 11-12 (Bayard 2021) — under-11s need AI to make pacing decisions for them
- **Dialogic reading:** β=0.51 comprehension improvement (Child Development ~2022)
- **Cognitive load reversal:** pauses help low-WMC children only (Pinelli 2025)
- **Physical breaks:** 10-min breaks improve attention in 4th graders — suggest breaks after ~15-20 min

---

## Server Stack (House Server)

```
House server
├── Ollama (Llama 3B)
├── cyberharness router
├── etutor-server
├── Pterodactyl
│   └── Paper + GeyserMC + ComputerCraft
└── Calibre-Web
```

---

## Updated BOM Summary

| Item | Est. Price |
|---|---|
| CM4 4GB | £0 (owned) |
| Carrier PCB + components | ~£57 |
| Display + touch | ~£63 |
| NVMe SSD 256GB | £25 |
| ESP32-S3 + power ICs | ~£12 |
| Audio (mic + amp + speaker) | ~£7 |
| Battery 6000mAh | £22 |
| Enclosure | £10 |
| Misc | £5 |
| **Device subtotal** | **~£202** |
| **Dock** | **~£18** |
| **Per-device total** | **~£220** |
| **6 devices** | **~£1,320** |

---

## Open Questions Remaining

- CM4 Lite vs standard (WiFi/BT onboard vs external module)
- ComputerCraft web IDE — specific plugin selection
- Custom wake word ("Hey Tutor") — Porcupine training needed
- Minecraft challenge difficulty calibration (auto by age vs parent config)
- Enclosure drop-resistance (TPU bumper vs Mobius plastic panel)
- Speaker placement (front vs side-firing)
