# Carrier PCB Design Constraints

## Module Compatibility
- Must support full Jetson Orin SO-DIMM family via 260-pin DDR4 SO-DIMM socket
- Validated modules: Orin Nano 4GB, Orin Nano 8GB, Orin NX 8GB, Orin NX 16GB
- Do not make assumptions that break NX compatibility (power rails, GPIO assignment)

## Form Factor
- Clamshell ultrawide — 12.3" display footprint, matching CM Deck reference
- Board must fit within lower half of clamshell alongside keyboard PCB and battery cells
- 4-layer PCB (JLCPCB stackup)

## Display
- 12.3" ultrawide eDP panel, no touch
- eDP FPC connector on carrier
- No DSI, no touch controller

## Cooling
- 4-pin PWM fan header (2.54mm JST) for 30×30×7mm blower
- Fan PWM driven from Jetson GPIO or carrier MCU
- Heatsink mounts directly to module — leave clearance above SO-DIMM socket

## Connectivity
- USB hub: USB2514B 4-port USB 2.0
- USB-C ports: minimum 2× USB-C (one for charging, one host)
- USB-A: 1× for peripherals
- Gigabit Ethernet: RJ45 (optional — may omit for space)
- M.2 M-key 2280: NVMe SSD
- FPC connector to keyboard PCB
- No trackpad — removed, redundant on TUI-only machine

## Mesh Radio (RNode)
- SX1276 LoRa IC (868MHz EU), SPI to RP2040 MCU
- RP2040 presents as USB serial to Jetson (RNode firmware)
- SMA edge-mount connector for external antenna
- Separate from main USB hub — direct USB connection to Jetson

## Power
- Input: USB-C PD (12V negotiated via CH224K or FUSB302)
- Battery: 2× 21700 Li-ion parallel via BQ24650 charger
- Boost: XL6009 or MT3608, cells → 12V Jetson VDD_IN
- Fuel gauge: MAX17048 (I2C)
- Load switch: AP22653 on Jetson rail
- 3.3V LDO for logic, RTC coin cell

## Audio
- PCM5100A I2S DAC
- TPA6132A2 headphone amp
- 3.5mm TRS jack

## Misc
- PCF8563 RTC with coin cell
- 1.3" SH1106 SPI OLED (status display — battery, mesh status, model mode)
- ESD protection on all USB lines (TPD4EUSB30)
- Power button with tactile switch + header
