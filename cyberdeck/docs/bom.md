# Bill of Materials

Prices approximate, sourced from JLCPCB/Mouser/AliExpress/Amazon/RS Components.
Working budget: **~£850–900** including one PCB re-spin contingency.

---

## Dev Phase (one-time, bench validation)

| Item | Part | Source | Est. Price |
|---|---|---|---|
| Jetson Orin Nano Dev Kit | 945-13766-0000-000 | RS Components | £238 |
| Bench RNode | Heltec LoRa32 v3 | AliExpress | £15 |
| Throat mic | TENQ walkie-talkie throat mic + USB audio adapter | Amazon | £20 |
| **Subtotal** | | | **£273** |

---

## Final Build — Core

| Item | Part | Source | Est. Price |
|---|---|---|---|
| SoM | Jetson Orin Nano 8GB (900-13767-0030-000) | Arrow/RS | £220 |
| SO-DIMM socket | 260-pin DDR4 SO-DIMM | LCSC | £2 |
| NVMe SSD | 256GB M.2 2280 | Amazon | £25 |
| **Subtotal** | | | **£247** |

> SO-DIMM socket is pin-compatible with full Orin family — Nano 4GB/8GB, NX 8GB/16GB.

---

## Display

| Item | Part | Source | Est. Price |
|---|---|---|---|
| Display | BOE NV127H4M-NX1 — 12.7" ultrawide eDP 1.4 4-lane, 2880×864, 500 nit, 120Hz, no touch | AliExpress | £35–45 |
| eDP FPC cable | 40-pin eDP, NV127H4M-NX1 spec | LCSC | £3 |
| **Subtotal** | | | **£38–48** |

> No touchscreen — redundant on TUI machine.  
> Panel confirmed: BOE NV127H4M-NX1, eDP 1.4 4-lane 40-pin, ADS (IPS-type), 12.7" — 4mm wider than CM Deck reference, minor enclosure adjustment needed.  
> Alternative: VSDISPLAY K003374 kit (panel + controller) ~£45, useful for bench validation before carrier PCB.  
> Note: true 12.3" ultrawide eDP panels do not exist in the consumer supply chain — all 12.3" ultrawide panels use automotive LVDS or GMSL.

---

## Keyboard

75% layout — alpha + F-row + arrow keys + nav column (Del, PgUp, PgDn, Home, End).
Fits naturally in the 12.3" ultrawide lower shell.

| Item | Part | Qty | Source | Est. Price |
|---|---|---|---|---|
| Switches | Kailh Choc V1 | 84 | Mechboards.co.uk | £45 |
| Keycaps | MBK blanks | 84 | Mechboards.co.uk | £35 |
| Keyboard MCU | RP2040 | 1 | LCSC | £2 |
| FPC connector | 24-pin 0.5mm pitch | 2 | LCSC | £1 |
| **Subtotal** | | | | **£83** |

---

## Power

| Item | Part | Notes | Est. Price |
|---|---|---|---|
| Cells | 2× Samsung 50E 21700 5000mAh | ~37Wh total | £15 |
| Charger IC | BQ24650 | CC/CV charger | £3 |
| Boost converter | XL6009 | Cells → 12V Jetson VDD_IN | £1 |
| Fuel gauge | MAX17048 | I2C, 1% accuracy | £2 |
| Load switch | AP22653 | Power sequencing | £1 |
| USB-C PD sink | CH224K | Negotiate 12V from PD charger | £1 |
| **Subtotal** | | | **£23** |

---

## Carrier PCB ICs

| Item | Part | Notes | Est. Price |
|---|---|---|---|
| USB hub | USB2514B | 4-port USB 2.0 | £3 |
| USB MUX | FSUSB42MUX | Host/device switching | £1 |
| Audio DAC | PCM5100A | I2S stereo DAC | £3 |
| Headphone amp | TPA6132A2 | 3.5mm output | £2 |
| RTC | PCF8563 | Coin cell backup | £1 |
| OLED | 1.3" SH1106 SPI | Status display | £5 |
| MEMS mic | ICS-43434 | I2S, on-board mic | £2 |
| ESD protection | TPD4EUSB30 | All USB lines, × 4 | £4 |
| Passives, connectors, misc | — | Resistors, caps, headers | £10 |
| **Subtotal** | | | **£31** |

---

## Mesh Radio (RNode — on carrier PCB)

| Item | Part | Notes | Est. Price |
|---|---|---|---|
| LoRa IC | SX1276 | 868MHz EU, SPI | £4 |
| MCU | RP2040 | RNode firmware, USB serial to Jetson | £2 |
| TCXO | 32MHz ±2ppm | SX1276 reference clock | £2 |
| RF switch | SKY13350 | TX/RX switching | £2 |
| SMA connector | Edge-mount SMA | Enclosure cutout | £2 |
| Antenna | 868MHz half-wave whip | External, detachable | £5 |
| **Subtotal** | | | **£17** |

---

## Cooling

| Item | Part | Notes | Est. Price |
|---|---|---|---|
| Fan | 30×30×7mm blower, 4-pin PWM | Rear vent exhaust | £6 |
| Heatsink | Jetson Orin Nano heatsink | Direct module contact | £4 |
| **Subtotal** | | | **£10** |

---

## Enclosure

| Item | Notes | Est. Price |
|---|---|---|
| Hinges | McMaster 1541A3 + 1541A4 (360° friction, left/right) | £25 |
| Heat-set inserts | M3, ~30 off | £4 |
| Screws | M3×6, M3×10 assorted | £4 |
| Filament | PLA/PETG for clamshell print | £10 |
| **Subtotal** | | **£43** |

---

## PCB Fabrication (JLCPCB, 5 off each)

| Board | Layers | Est. Price |
|---|---|---|
| Carrier PCB | 4 | £30 |
| Keyboard PCB | 2 | £8 |
| **Subtotal** | | **£38** |

---

## Misc

| Item | Est. Price |
|---|---|
| FPC cables, JST connectors, wire | £10 |
| Coin cell (RTC backup) | £2 |
| M3 standoffs | £3 |
| USB-C cable (bench) | £5 |
| Misc passives, solder, flux | £8 |
| **Subtotal** | **£28** |

---

## Budget Summary

| Phase / Category | Est. Cost |
|---|---|
| Dev phase (bench validation) | £273 |
| Core (module + SSD) | £247 |
| Display (BOE NV127H4M-NX1) | £38–48 |
| Keyboard (75%) | £83 |
| Power | £23 |
| Carrier PCB ICs | £31 |
| RNode (on carrier) | £17 |
| Cooling | £10 |
| Enclosure | £43 |
| PCB fabrication | £38 |
| Misc | £28 |
| **Total** | **~£831–861** |
| PCB re-spin contingency | £40 |
| **Working budget** | **~£900** |

---

## Deferred / Not Included

| Item | Reason |
|---|---|
| Trackpad (Cirque 40mm) | Removed — redundant on TUI-only machine |
| Touch digitizer | Removed — no touch on display |
| EMG subvocalization hardware | Early research only — see `docs/research/voice-input.md` |
| Jetson Orin NX upgrade | Module swap possible later, same carrier PCB |
