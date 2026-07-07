# Bill of Materials

Work in progress — prices approximate, sourced from JLCPCB/Mouser/AliExpress.

## Core

| Item | Part | Source | Est. Price |
|---|---|---|---|
| SoM | Jetson Orin Nano 8GB (900-13767-0030-000) | Arrow/RS | £220 |
| SO-DIMM socket | 260-pin DDR4 SO-DIMM | LCSC | £2 |
| NVMe SSD | 256GB M.2 2280 | Amazon | £25 |

## Display

| Item | Part | Notes |
|---|---|---|
| Display | 10–12" eDP panel | TBD — target 1920×1200 IPS |
| eDP cable | 30-pin eDP FPC | Match panel spec |

## Keyboard

| Item | Part | Qty | Source |
|---|---|---|---|
| Switches | Kailh Choc V1 | ~54 | Mechboards.co.uk |
| Keycaps | MBK blanks or legend | 54 | Mechboards.co.uk |
| Keyboard MCU | RP2040 or ATmega32U4 | 1 | LCSC |
| FPC connector | 24-pin 0.5mm pitch | 2 | LCSC |

## Power

| Item | Part | Notes |
|---|---|---|
| Cells | 2× Samsung 50E 21700 5000mAh | ~37Wh total |
| Charger IC | BQ24650 | CC/CV LiPo charger |
| Boost converter | MT3608 or XL6009 | 8.4V → 12V |
| Fuel gauge | MAX17048 | I2C, 1% accuracy |
| Load switch | AP22653 | Power sequencing |
| USB-C PD sink | FUSB302 or CH224K | Trigger 12V from PD charger |

## Carrier PCB ICs

| Item | Part | Notes |
|---|---|---|
| USB hub | USB2514B | 4-port USB 2.0 |
| USB MUX | FSUSB42MUX | Host/device switching |
| Audio DAC | PCM5100A | I2S stereo DAC |
| Headphone amp | TPA6132A2 | 3.5mm output |
| RTC | PCF8563 | Coin cell backup |
| OLED controller | SH1106 / SSD1306 | 1.3" status display |
| ESD protection | TPD4EUSB30 | All USB lines |

## Enclosure

| Item | Notes |
|---|---|
| Hinges | McMaster 1541A3 + 1541A4 (360° friction) |
| Heat-set inserts | M3, ~30 off |
| Screws | M3×6, M3×10 assorted |
| Trackpad | Cirque 40mm TM040040 |

## PCB Fabrication (JLCPCB estimate)

| Board | Layers | Est. Cost (5 off) |
|---|---|---|
| Carrier PCB | 4 | ~£30 |
| Keyboard PCB | 2 | ~£8 |
