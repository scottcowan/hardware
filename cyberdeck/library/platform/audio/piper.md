# Piper TTS — Reference & Troubleshooting

Offline neural TTS. Runs on CPU, ~150ms latency on Jetson.

## Usage

```bash
# Pipe text to speech via aplay
echo "Hello from the Slow Zone" | \
  piper --model ~/.local/share/piper/voices/en_GB-alba-medium.onnx \
        --output-raw | \
  aplay -r 22050 -f S16_LE -t raw -

# tts alias (set in 03-tui-stack.sh)
echo "Hello" | tts
```

## Common Failures

### Illegal instruction / SIGILL

**Cause:** Piper binary built with AVX2 — not supported on Jetson ARM.

**Fix:** Install from pip (ARM-native):
```bash
pip3 install piper-tts
# Use python module instead of binary:
python3 -m piper --model <voice.onnx> --output-raw
```

---

### No audio output / aplay error

**Symptom:** Piper runs but no sound, or `aplay: set_params:...` error.

**Cause A:** Wrong sample rate. Piper outputs 22050Hz but aplay defaults
may not match.
```bash
# Always specify format explicitly:
aplay -r 22050 -f S16_LE -t raw -c 1 -
```

**Cause B:** No audio device. Check:
```bash
aplay -l          # list playback devices
aplay -L          # list PCM devices
```

**Cause C:** PulseAudio not running:
```bash
pulseaudio --start
# or use paplay instead of aplay:
piper ... --output-raw | paplay --raw --rate=22050 --format=s16le --channels=1
```

---

### Voice sounds robotic / bad quality

**Cause:** Using `--output-raw` without correct format flags in aplay.
Quality loss from format mismatch.

**Fix:** Use exact format for the voice model. Alba-medium outputs
22050Hz 16-bit mono:
```bash
aplay -r 22050 -f S16_LE -t raw -c 1 -
```

## Voices

Voices live in `~/.local/share/piper/voices/`. Download from:
`huggingface.co/rhasspy/piper-voices`

### Installed (from 05-audio.sh)
- `en_GB-alba-medium.onnx` — clear British female, 22050Hz

### Other recommended voices
```bash
# US English male, natural
wget https://huggingface.co/rhasspy/piper-voices/resolve/main/en/en_US/ryan/medium/en_US-ryan-medium.onnx

# US English female, high quality
wget https://huggingface.co/rhasspy/piper-voices/resolve/main/en/en_US/kathleen/low/en_US-kathleen-low.onnx
```

## Python API

```python
import subprocess

def speak(text: str, voice: str = "~/.local/share/piper/voices/en_GB-alba-medium.onnx"):
    proc = subprocess.run(
        ["python3", "-m", "piper", "--model", voice, "--output-raw"],
        input=text.encode(),
        capture_output=True,
    )
    subprocess.run(
        ["aplay", "-r", "22050", "-f", "S16_LE", "-t", "raw", "-c", "1", "-"],
        input=proc.stdout,
        capture_output=True,
    )
```
