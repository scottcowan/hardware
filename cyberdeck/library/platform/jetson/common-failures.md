# Jetson Orin Nano — Common Failures

Symptom→cause→fix for recurring issues on JetPack Ubuntu.

---

## Power & Boot

### nvpmodel mode not persisting after reboot

**Symptom:** `sudo nvpmodel -q` shows wrong mode after reboot.

**Cause:** Mode set manually but systemd service not enabled, or
`/etc/nvpmodel.conf` not updated.

**Fix:**
```bash
sudo nvpmodel -m 1           # set desired mode (1=10W, 0=15W MAXN)
sudo systemctl enable nvpmodel
sudo systemctl start nvpmodel
sudo nvpmodel -q             # verify: should show MODE_1_10W or similar
```

---

### Jetson won't boot — stuck at NVIDIA logo

**Symptom:** Boot hangs at splash screen, no terminal output.

**Cause A:** Corrupt SD card / NVMe. Check with another storage device.

**Cause B:** Bad JetPack flash. Reflash with SDK Manager from Ubuntu host.

**Cause C:** Power supply too weak. Jetson Orin Nano needs 5V/3A minimum.
The dev kit ships with a 65W USB-C PSU — use it.

**Diagnosis:**
```bash
# Connect USB-C to host, check serial console
# On host:
screen /dev/ttyACM0 115200   # or /dev/ttyUSB0
# Reboot Jetson — boot log will appear in serial console
```

---

### Thermal throttling under AI inference load

**Symptom:** Inference speed drops mid-session, `jtop` shows CPU/GPU clocks
reduced.

**Cause:** Thermal protection kicking in. Normal behaviour — the heatsink
is at thermal limit.

**Fix (immediate):**
```bash
sudo jetson_clocks --restore   # restore clocks after throttle event
```

**Fix (preventive):** Ensure heatsink is properly seated with thermal paste.
Add 30mm PWM fan. Check fan is spinning under load.

**Monitor:**
```bash
sudo jtop   # watch Temp row — throttle begins around 70-80°C
```

---

## Display

### HDMI display not detected on cold boot

**Symptom:** Monitor shows no signal on first power-on. Works after reboot
or hotplug.

**Cause:** HDMI hotplug detection race — monitor powers up after Jetson
has already initialised the display subsystem.

**Fix (temporary):** Power monitor before Jetson, or hotplug HDMI cable
after boot.

**Fix (persistent):**
```bash
# Force HDMI output regardless of hotplug
sudo nano /boot/extlinux/extlinux.conf
# Add to APPEND line: video=HDMI-A-1:1920x1080@60
```

---

### Display resolution wrong / overscan

**Symptom:** Display shows correct signal but wrong resolution or black
borders.

**Fix:**
```bash
xrandr --output HDMI-1 --mode 1920x1080   # X11
# or for Wayland:
wlr-randr --output HDMI-A-1 --mode 1920x1080
```

---

## CUDA & GPU

### CUDA version mismatch after JetPack upgrade

**Symptom:** `import torch` fails with CUDA version error, or faster-whisper
crashes with `CUBLAS_STATUS_ALLOC_FAILED`.

**Cause:** PyTorch or CUDA toolkit version doesn't match JetPack's CUDA.
JetPack has its own CUDA stack — not the same as desktop NVIDIA CUDA.

**Check versions:**
```bash
cat /usr/local/cuda/version.txt    # CUDA version
python3 -c "import torch; print(torch.version.cuda)"  # what PyTorch expects
dpkg -l | grep cuda                # installed CUDA packages
```

**Fix:** Install PyTorch wheel built for your specific JetPack version.
```bash
# Find correct wheel at: https://forums.developer.nvidia.com/t/pytorch-for-jetson
# Example for JetPack 6.x:
pip3 install --pre torch torchvision torchaudio \
  --index-url https://download.pytorch.org/whl/nightly/cu121
```

**CUBLAS_STATUS_ALLOC_FAILED specifically:**
Docker containers using `nvidia/cuda` SBSA base images include cuBLAS
built for server GPUs, not Jetson iGPU. Fix: bind-mount host cuBLAS:
```bash
docker run -v /usr/local/cuda/lib64:/usr/local/cuda/lib64 ...
```

---

### GPU not available to Python / CUDA not found

**Symptom:** `torch.cuda.is_available()` returns False.

**Cause A:** User not in `video` or `render` group.
```bash
sudo usermod -aG video,render $USER
# Log out and back in
```

**Cause B:** Wrong PyTorch build (CPU-only wheel).
```bash
python3 -c "import torch; print(torch.__version__)"
# Should include '+cu' suffix e.g. '2.1.0+cu121'
```

**Cause C:** CUDA libraries not on LD_LIBRARY_PATH.
```bash
export LD_LIBRARY_PATH=/usr/local/cuda/lib64:$LD_LIBRARY_PATH
```

---

## USB & Connectivity

### USB device not appearing on /dev/ttyACM0 or /dev/ttyUSB0

**Symptom:** RNode, Arduino, or other USB serial device not detected.

**Cause A:** User not in `dialout` group.
```bash
sudo usermod -aG dialout $USER
# Log out and back in, then replug device
```

**Cause B:** udev race — device appears then disappears.
```bash
dmesg | tail -20   # look for USB attach/detach events
udevadm monitor    # watch udev events in real time
```

**Cause C:** Wrong cable — USB-C cables that are power-only (no data).
Try a known-good data cable.

---

### USB-C alt mode (DisplayPort) not negotiating

**Symptom:** USB-C to DisplayPort adapter not showing video output.

**Cause:** Alt mode negotiation requires DP alt mode support on both cable
and host controller. Not all USB-C cables support alt mode.

**Requirements:** USB-C cable rated for Thunderbolt 3/4 or USB4, or
explicitly labeled "DP alt mode" support.

**Diagnosis:**
```bash
dmesg | grep -i "displayport\|dp alt\|typec"
sudo cat /sys/class/typec/port0/power_role
```

---

## Storage

### NVMe SSD not detected

**Symptom:** `lsblk` shows no NVMe device, or device appears intermittently.

**Cause A:** M.2 slot not firmly seated. Re-seat the SSD.

**Cause B:** PCIe power not available. Check carrier board power sequencing.

**Cause C:** Incompatible NVMe. Some drives require PCIe Gen 4 — Jetson
Orin Nano supports Gen 3 ×4. Most modern drives are backward compatible
but check the drive's spec sheet.

**Diagnosis:**
```bash
lspci | grep -i nvme
nvme list
dmesg | grep -i nvme
```

---

### SD card corruption / filesystem errors

**Symptom:** Random crashes, filesystem read-only errors, corrupted files.

**Cause:** SD card failure (common on Jetson dev kits used heavily) or
improper shutdown without graceful poweroff.

**Fix:** Switch to NVMe SSD for the OS — far more reliable under
write-heavy workloads like AI inference.

**Recovery:**
```bash
sudo fsck -y /dev/mmcblk0p1   # repair filesystem (unmounted)
```

---

## JetPack & Software

### apt-get fails with JetPack repository errors

**Symptom:** `sudo apt-get update` fails with GPG or 404 errors on
`repo.download.nvidia.com`.

**Cause:** NVIDIA repository GPG key expired or repository URL changed
in newer JetPack versions.

**Fix:**
```bash
# Refresh NVIDIA apt key
sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys F60F4B3D7FA2AF80
sudo apt-get update
```

---

### jetson-stats (jtop) shows wrong power readings

**Symptom:** Power draw in jtop looks incorrect after kernel update.

**Cause:** INA3221 power monitor driver path changes between JetPack versions.

**Manual read:**
```bash
# Find the correct sysfs path
find /sys/bus/i2c -name "in_power*_input" 2>/dev/null
cat /sys/bus/i2c/drivers/ina3221x/*/iio:device*/in_power0_input
```

---

### jetson_clocks not taking effect

**Symptom:** `sudo jetson_clocks` runs without error but clocks unchanged.

**Cause:** nvpmodel overrides jetson_clocks. Must set nvpmodel first.

**Fix:**
```bash
sudo nvpmodel -m 0       # MAXN mode first
sudo jetson_clocks       # then set max clocks
```

**Alias (already in 04-jetson-tweaks.sh):**
```bash
alias maxperf='sudo nvpmodel -m 0 && sudo jetson_clocks'
```
