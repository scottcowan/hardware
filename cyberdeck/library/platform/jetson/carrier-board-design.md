# Jetson Orin Nano/NX — Custom Carrier Board Design Guide

Summary of key design requirements for a custom carrier PCB.
Source: https://thinkrobotics.com/blogs/tutorials/complete-guide-to-designing-custom-carrier-boards-for-nvidia-jetson-modules
Authoritative reference: NVIDIA OEM Product Design Guide (developer.nvidia.com)

---

## Module Connector

- **260-pin SO-DIMM** — same mechanical footprint across Orin Nano 4GB/8GB and Orin NX 8GB/16GB
- One carrier board design supports all four modules — design power delivery for the NX (higher TDP) if supporting both
- Tight alignment tolerance — no keep-out zone violations permitted
- Mounting holes must match NVIDIA spec exactly; use standoffs for mechanical support

---

## Power Requirements

| Rail | Voltage | Peak current | Notes |
|---|---|---|---|
| Module input | 5V | 2–4A peak | Orin Nano 7–15W typical |
| Board input | 12V typical | — | Stepped down via regulators |
| Peripherals | 3.3V, 1.8V | — | Auxiliary rails |

- Size power supply at **≥150% of maximum load** — AI workload transients spike hard
- Orin Nano: 7–15W; Orin NX: higher — design for NX ceiling if supporting both
- **Inrush limiting** required: TVS diodes, Schottky diodes
- Reverse polarity protection required
- Overvoltage clamping required

### Power Sequencing

`SYS_RESET` signal coordinates power sequencing for carrier board peripherals.
Improper sequencing is the most common cause of peripheral damage at startup.

---

## GPIO Voltage Domain — Critical

**Orin module GPIOs are 1.8V.** Direct connection to 3.3V peripherals without
level shifting will damage the module. Every GPIO interface to external hardware
needs a level shifter.

```
Module GPIO (1.8V) → level shifter → external peripheral (3.3V)
```

---

## Required Interfaces

| Interface | Notes |
|---|---|
| 260-pin SO-DIMM | Module connector |
| PCIe Gen 3 | High-speed data path |
| USB 3.0 + USB 2.0 | Both required |
| Gigabit Ethernet | RGMII, length matching required |
| MIPI CSI camera | At least one interface |

## Optional (for cyberdeck carrier)

| Interface | Notes |
|---|---|
| M.2 Key M | NVMe SSD — include |
| M.2 Key E | Wi-Fi/BT — include if using Orin Nano Lite |
| 40-pin GPIO header | Level shifting to 3.3V required |
| USB hub (USB2514B) | Port expansion |

---

## Signal Integrity Requirements

| Signal | Impedance | Notes |
|---|---|---|
| USB 2.0 differential | 90Ω | Standard diff pair rules |
| USB 3.0 differential | 90Ω diff / 45Ω single-ended | Strict routing |
| MIPI CSI-2 | 90–100Ω | Inner layers only; 1.5 Gbps/lane |
| MIPI CSI-2 reference | Continuous ground above and below | No plane splits |
| Gigabit Ethernet (RGMII) | — | Length match all signals |
| General diff pairs | 90–100Ω | Away from clocks and noise |

- Route differential pairs **symmetrically on same layer**
- Minimise length mismatch within a pair
- Continuous ground plane under all high-speed traces — no splits

---

## PCB Stackup

| Board | Layers | When |
|---|---|---|
| Standard cyberdeck carrier | **4-layer** | Sufficient for our interface count |
| Dense routing / many diff pairs | 6–8 layer | If needed |

- Power and GND on inner layers — shields outer signal layers
- Standard fab rules sufficient: **6/6 mil traces, 0.3mm vias**
- JLCPCB 4-layer JLC04161H-7628 stackup is the reference

---

## Thermal

- Module junction temp limit: **95–97°C** — throttles above this
- Passive heatsink: adequate for Nano at moderate AI load
- **Active cooling (PWM fan) required** for sustained inference — already in cyberdeck design (30mm blower)
- Thermal vias under all power regulators
- Keep heat sources away from oscillators and voltage references

---

## Design Checklist

### Schematic
- [ ] Power tree: input → regulators → module + all peripherals
- [ ] Power supply rated ≥150% max load
- [ ] SYS_RESET sequencing correct
- [ ] Reverse polarity + overvoltage protection
- [ ] Inrush limiting (TVS/Schottky)
- [ ] GPIO level shifting: 1.8V module → 3.3V peripherals everywhere
- [ ] RJ45 with integrated magnetics (magnetic isolation)
- [ ] Clock and reset trees defined

### Layout
- [ ] SO-DIMM keep-out zones enforced — no violations
- [ ] Mounting holes match NVIDIA spec
- [ ] Fiducial marks for automated assembly
- [ ] Thermal vias under all power components
- [ ] Heat sources separated from temperature-sensitive circuits
- [ ] MIPI CSI traces on inner layers, full ground reference planes
- [ ] Differential pair symmetry verified (same layer, length matched)
- [ ] RGMII Ethernet length-matched
- [ ] USB impedances verified (90Ω diff, 45Ω single-ended for USB 3.0)
- [ ] No ground plane splits under high-speed traces

### Fabrication
- [ ] 4-layer stackup confirmed with JLCPCB
- [ ] 6/6 mil design rules verified
- [ ] Prototype run: 5 boards minimum

---

## Common Mistakes

1. **Wrong power sequencing** — SYS_RESET not used correctly → peripheral damage
2. **Undersized power supply** — AI transients need 150% headroom
3. **1.8V GPIOs connected directly to 3.3V** — module damage
4. **No thermal vias under regulators** — thermal runaway
5. **MIPI CSI ground plane splits** — signal integrity failure at 1.5 Gbps
6. **SO-DIMM misalignment** — keep-out violations
7. **Designing for Nano only** — if carrier will ever take an NX, design power for NX from day one

---

## Project Timeline

| Phase | Duration |
|---|---|
| Schematic | 2–3 weeks |
| Layout | 3–4 weeks |
| Fabrication (JLCPCB) | 2–3 weeks |
| Bring-up / software | 3–6 weeks |
| **Total to first prototype** | **8–16 weeks** |

Production unit cost at 100–1000 qty: $50–200/board.
