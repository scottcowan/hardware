# Jetson Cyberdeck

Open-hardware clamshell cyberdeck built around the NVIDIA Jetson Orin Nano 8GB, with a custom carrier PCB, integrated low-profile mechanical keyboard, eDP display, and on-device AI inference via Ollama/llama.cpp.

Inspired by [CM Deck](https://github.com/sb-ocr/cmdeck) (CC BY-NC-SA 4.0).

---

## Hardware Overview

| Component | Detail |
|---|---|
| SoM | NVIDIA Jetson Orin Nano 8GB (900-13767-0030-000) |
| GPU | 1024-core Ampere, 40 TOPS |
| CPU | 6-core ARM Cortex-A78AE |
| RAM | 8 GB LPDDR5 |
| Storage | NVMe SSD via M.2 M-key on carrier |
| Display | 10–12" eDP touchscreen |
| Keyboard | Kailh Choc V1 low-profile, QMK firmware |
| Trackpad | Cirque 40mm capacitive |
| Battery | 2× 21700 Li-ion cells (~37Wh) |
| Power | Boost to 12V, BQ24650 charger, MAX17048 fuel gauge |
| Enclosure | 3D-printed clamshell, McMaster friction hinges |
| AI runtime | Ollama / llama.cpp (Llama 3.2 3B / 7B quantized) |

---

## Repository Structure

```
jetson-cyberdeck/
├── hardware/
│   ├── carrier-pcb/        # KiCad project — Jetson carrier board
│   ├── keyboard-pcb/       # KiCad project — Kailh Choc keyboard
│   └── enclosure/          # FreeCAD / STL files
├── firmware/
│   └── keyboard/           # QMK config for keyboard MCU
├── software/
│   └── setup/              # Jetson OS setup scripts, Ollama install
├── docs/
│   ├── bom.md              # Bill of materials
│   ├── power.md            # Power architecture notes
│   └── build-log.md        # Build progress log
└── references/             # Datasheets, reference schematics
```

---

## Status

- [ ] Carrier PCB schematic
- [ ] Carrier PCB layout
- [ ] Keyboard PCB
- [ ] Enclosure design
- [ ] Power architecture
- [ ] OS + AI software setup
- [ ] First build

---

## License

CC BY-NC-SA 4.0 — non-commercial, share-alike.
