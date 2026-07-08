# Cyberdeck

Open-hardware clamshell ultrawide cyberdeck built around the NVIDIA Jetson Orin Nano 8GB, with a custom carrier PCB, 75% mechanical keyboard, eDP display, on-device AI inference, and Reticulum LoRa mesh radio.

---

## Hardware Overview

| Component | Detail |
|---|---|
| SoM | NVIDIA Jetson Orin Nano 8GB (900-13767-0030-000) |
| GPU | 1024-core Ampere, 40 TOPS |
| CPU | 6-core ARM Cortex-A78AE |
| RAM | 8 GB LPDDR5 (shared CPU+GPU) |
| Storage | NVMe SSD via M.2 M-key on carrier |
| Display | BOE NV127H4M-NX1 — 12.7" ultrawide eDP, 2880×864, 500 nit, no touch |
| Keyboard | 75% Kailh Choc V1 low-profile (~84 keys), QMK firmware |
| Battery | 2× 21700 Li-ion cells (~37Wh) |
| Power | XL6009 boost to 12V, BQ24650 charger, MAX17048 fuel gauge |
| Mesh radio | SX1276 868MHz LoRa (RNode firmware), Reticulum network stack |
| Cooling | 30mm PWM blower, rear vent slots |
| Enclosure | 3D-printed clamshell ultrawide, McMaster friction hinges |
| AI runtime | Ollama — Llama 3.2 3B q4, local inference |
| STT | whisper.cpp small, CUDA accelerated — pending bench validation |
| Module compat | SO-DIMM pin-compatible with full Orin family (Nano/NX) |

---

## Repository Structure

```
cyberdeck/
├── hardware/
│   ├── carrier-pcb/    # KiCad — Jetson carrier board
│   └── keyboard-pcb/   # KiCad — 75% Choc keyboard
├── firmware/
│   └── keyboard/       # QMK config
├── software/
│   └── setup/          # First-boot setup scripts
├── docs/
│   ├── bom.md
│   ├── power.md
│   ├── build-log.md
│   └── research/
└── references/
```

---

## Status

- [ ] Carrier PCB schematic
- [ ] Carrier PCB layout
- [ ] Keyboard PCB
- [ ] Enclosure design
- [ ] OS + AI software setup
- [ ] First build

---

## Working Budget

~£940 — see [docs/bom.md](docs/bom.md) for full breakdown.
