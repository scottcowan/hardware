# hardware

Open-hardware projects — custom PCBs, enclosures, and firmware.

## Projects

| Project | Description | Status |
|---|---|---|
| [cyberdeck](cyberdeck/) | Clamshell ultrawide cyberdeck, Jetson Orin Nano 8GB, local AI inference, Reticulum mesh | In design |
| [eink-tutor](eink-tutor/) | E-ink educational device with STT, low-power, always-on | In design |

---

## Repository Structure

```
hardware/
├── cyberdeck/          # Jetson Orin Nano 8GB clamshell cyberdeck
│   ├── hardware/       # KiCad PCBs (carrier, keyboard)
│   ├── firmware/       # QMK keyboard firmware
│   ├── software/       # Jetson setup scripts
│   ├── docs/           # BOM, power, build log, research
│   └── references/     # Datasheets, reference schematics
└── eink-tutor/         # E-ink STT educational device
    ├── hardware/       # KiCad PCB
    ├── firmware/       # MCU firmware
    ├── software/       # Application software
    ├── docs/           # BOM, design notes
    └── references/     # Datasheets
```

---

## License

CC BY-NC-SA 4.0 — non-commercial, share-alike.
