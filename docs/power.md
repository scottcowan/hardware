# Power Architecture

## Power Budget

| Consumer | Typical | Peak |
|---|---|---|
| Jetson Orin Nano 8GB | 10W | 15W |
| Display (10") | 2W | 3W |
| USB hub + peripherals | 1W | 2W |
| Keyboard MCU | 0.1W | 0.1W |
| OLED + misc | 0.2W | 0.2W |
| **Total** | **~13W** | **~20W** |

**Battery:** 2× Samsung 50E 21700 = 2 × 3.7V × 5Ah = 37Wh  
**Runtime estimate:** 37Wh ÷ 13W ≈ **2.8 hours typical**, 1.8 hours heavy AI load

---

## Voltage Rails

| Rail | Source | Consumers |
|---|---|---|
| 12V | Boost from cells | Jetson VDD_IN |
| 5V | Buck from 12V | USB hub, display backlight |
| 3.3V | LDO from 5V | RTC, OLED, misc logic |
| VBUS 5V | Pass-through / PD | USB-C host ports |

---

## Cell Configuration

- 2× 21700 in **parallel** (2S would give 8.4V max; parallel stays at 3.7–4.2V and simplifies BMS)
- Parallel 2P: 10Ah at 3.7–4.2V = 37–42Wh
- Boost from 3.7–4.2V → 12V using XL6009 (up to 4A output, ~85% efficiency)

> Note: 4.2V × 10A source / 85% eff → 12V output ≈ 3A max. At 15W load that's 1.25A @ 12V — well within margin.

---

## Charging

- **USB-C PD input** — FUSB302 or CH224K negotiates 12V/2A (24W) from a PD charger
- **BQ24650** — synchronous buck charger, CV/CC, configurable via resistors for 4.2V/2A per cell (parallel cells charge as one)
- Charging indicator LED + fuel gauge readout on OLED

---

## Safety

- Fused cell output (polyfuse or blade fuse)
- Overcurrent protection via load switch (AP22653) on Jetson rail
- Cell reverse-polarity protection diode
- BQ24650 provides OVP, OCP, thermal regulation
