#!/bin/bash
# Audio stack for Jetson Orin Nano cyberdeck
# STT: SenseVoiceSmall (default) or faster-whisper (CUDA)
# TTS: Piper, VAD: Silero, Wake word: Porcupine
# Inspired by Sparky (Elecrow Jetson build) pipeline design
# Mic: TRRS 3.5mm or MEMS via carrier PCB

set -e

echo "==> Installing system audio dependencies"
sudo apt-get update
sudo apt-get install -y \
  alsa-utils \
  pulseaudio \
  pulseaudio-utils \
  python3-pip \
  python3-venv \
  ffmpeg \
  portaudio19-dev \
  python3-pyaudio \
  libasound2-dev

echo "==> Adding user to audio group"
sudo usermod -aG audio "$USER"

echo "==> Installing SenseVoiceSmall (FunASR — primary STT)"
pip3 install funasr modelscope

echo "==> Pre-downloading SenseVoiceSmall model"
python3 - <<'PYEOF'
from funasr import AutoModel
print("Downloading SenseVoiceSmall model (~245MB)...")
model = AutoModel(
    model="iic/SenseVoiceSmall",
    trust_remote_code=True,
    device="cuda",
)
print("SenseVoiceSmall ready.")
PYEOF

echo "==> Installing faster-whisper (fallback STT, CUDA-accelerated)"
pip3 install faster-whisper

echo "==> Pre-downloading Whisper base.en model (fallback)"
python3 - <<'PYEOF'
from faster_whisper import WhisperModel
print("Downloading whisper base.en model (fallback)...")
model = WhisperModel("base.en", device="cuda", compute_type="float16")
print("Whisper base.en ready.")
PYEOF

echo "==> Installing Silero VAD"
pip3 install silero-vad

echo "==> Installing Piper TTS"
pip3 install piper-tts

echo "==> Downloading Piper voice (en_GB-alba-medium)"
mkdir -p ~/.local/share/piper/voices
cd ~/.local/share/piper/voices
wget -q "https://huggingface.co/rhasspy/piper-voices/resolve/main/en/en_GB/alba/medium/en_GB-alba-medium.onnx" \
  -O en_GB-alba-medium.onnx
wget -q "https://huggingface.co/rhasspy/piper-voices/resolve/main/en/en_GB/alba/medium/en_GB-alba-medium.onnx.json" \
  -O en_GB-alba-medium.onnx.json
cd -
echo "    Voice downloaded: en_GB-alba-medium"

echo "==> Installing Porcupine wake word (Picovoice)"
pip3 install pvporcupine pvrecorder

echo "==> Installing Porcupine access key helper"
cat > ~/.config/porcupine.env <<'EOF'
# Get a free access key from https://console.picovoice.ai/
# Free tier: 1 wake word, non-commercial use
PORCUPINE_ACCESS_KEY=
EOF
echo "    NOTE: Add your Porcupine access key to ~/.config/porcupine.env"

echo "==> Writing voice pipeline (~/.local/bin/voice-query)"
mkdir -p ~/.local/bin
cat > ~/.local/bin/voice-query <<'PYEOF'
#!/usr/bin/env python3
"""
Cyberdeck voice query pipeline — Sparky-inspired.

Pipeline: Hear → Transcribe → Add context → Think → Speak

STT backends (--stt flag):
  sensevoice   SenseVoiceSmall via FunASR — faster, emotion detection (default)
  whisper      faster-whisper base.en — fallback, slightly higher accuracy

Usage:
  voice-query                        # VAD auto-stop, sensevoice STT
  voice-query --push-to-talk         # press Enter to stop recording
  voice-query --wake-word            # always-on Porcupine wake word loop
  voice-query --stt whisper          # use faster-whisper instead
  voice-query --no-context           # skip machine state injection
  voice-query --no-tts               # print response only
  voice-query --pipe "some text"     # skip mic entirely
"""

import argparse
import json
import os
import subprocess
import sys
import tempfile
import threading
import time
import wave

import numpy as np
import pyaudio

SAMPLE_RATE  = 16000
CHANNELS     = 1
CHUNK        = 512
VAD_THRESHOLD    = 0.5
SILENCE_DURATION = 0.8   # seconds of silence before stopping
OLLAMA_MODEL = "llama3.2:3b-instruct-q4_K_M"
OLLAMA_URL   = "http://localhost:11434/api/generate"


# ---------------------------------------------------------------------------
# Machine state context (Sparky "Add context" step)
# ---------------------------------------------------------------------------

def get_machine_context() -> str:
    """
    Inject live machine state into the prompt before inference.
    Mirrors Sparky's sensor context injection step.
    """
    import datetime
    lines = []

    # Time
    now = datetime.datetime.now()
    lines.append(f"Current time: {now.strftime('%H:%M, %A %d %B %Y')}")

    # Jetson power mode
    try:
        result = subprocess.run(
            ["sudo", "nvpmodel", "-q"], capture_output=True, text=True, timeout=2
        )
        for line in result.stdout.splitlines():
            if "Mode" in line or "NV Power" in line:
                lines.append(f"Power mode: {line.strip()}")
                break
    except Exception:
        pass

    # Battery / power (INA3221 on Jetson carrier)
    try:
        import glob
        power_files = glob.glob(
            "/sys/bus/i2c/drivers/ina3221x/*/iio:device*/in_power0_input"
        )
        if power_files:
            with open(power_files[0]) as f:
                mw = int(f.read().strip())
            lines.append(f"System power draw: {mw}mW")
    except Exception:
        pass

    # Reticulum mesh status
    try:
        result = subprocess.run(
            ["rnstatus", "--json"], capture_output=True, text=True, timeout=3
        )
        if result.returncode == 0:
            data = json.loads(result.stdout)
            ifaces = len(data.get("interfaces", []))
            lines.append(f"Reticulum mesh: {ifaces} interface(s) active")
    except Exception:
        lines.append("Reticulum mesh: status unknown")

    # Ollama loaded models
    try:
        import urllib.request
        with urllib.request.urlopen("http://localhost:11434/api/ps", timeout=2) as r:
            data = json.loads(r.read())
            loaded = [m["name"] for m in data.get("models", [])]
            if loaded:
                lines.append(f"Loaded models: {', '.join(loaded)}")
    except Exception:
        pass

    # Active tmux sessions
    try:
        result = subprocess.run(
            ["tmux", "list-sessions", "-F", "#{session_name}"],
            capture_output=True, text=True, timeout=2,
        )
        if result.returncode == 0 and result.stdout.strip():
            sessions = result.stdout.strip().splitlines()
            lines.append(f"tmux sessions: {', '.join(sessions)}")
    except Exception:
        pass

    if not lines:
        return ""

    return "--- System context ---\n" + "\n".join(lines) + "\n---\n"


# ---------------------------------------------------------------------------
# Audio recording
# ---------------------------------------------------------------------------

def record_push_to_talk() -> list:
    pa = pyaudio.PyAudio()
    stream = pa.open(
        format=pyaudio.paInt16, channels=CHANNELS,
        rate=SAMPLE_RATE, input=True, frames_per_buffer=CHUNK,
    )
    frames = []
    print("Recording... (press Enter to stop)", end="", flush=True)
    stop_event = threading.Event()
    threading.Thread(target=lambda: (input(), stop_event.set()), daemon=True).start()
    while not stop_event.is_set():
        frames.append(stream.read(CHUNK, exception_on_overflow=False))
    stream.stop_stream(); stream.close(); pa.terminate()
    return frames


def record_with_vad() -> list:
    from silero_vad import load_silero_vad
    import torch

    vad_model = load_silero_vad()
    pa = pyaudio.PyAudio()
    stream = pa.open(
        format=pyaudio.paInt16, channels=CHANNELS,
        rate=SAMPLE_RATE, input=True, frames_per_buffer=CHUNK,
    )
    frames = []
    silent_chunks = 0
    speaking_started = False
    silence_needed = int(SILENCE_DURATION * SAMPLE_RATE / CHUNK)

    print("Listening...", end="", flush=True)
    while True:
        data = stream.read(CHUNK, exception_on_overflow=False)
        frames.append(data)
        chunk_f32 = np.frombuffer(data, dtype=np.int16).astype(np.float32) / 32768.0
        prob = vad_model(torch.from_numpy(chunk_f32), SAMPLE_RATE).item()

        if prob > VAD_THRESHOLD:
            speaking_started = True
            silent_chunks = 0
            print(".", end="", flush=True)
        elif speaking_started:
            silent_chunks += 1
            if silent_chunks >= silence_needed:
                break

    print()
    stream.stop_stream(); stream.close(); pa.terminate()
    return frames


def frames_to_wav(frames: list) -> str:
    tmp = tempfile.NamedTemporaryFile(suffix=".wav", delete=False)
    with wave.open(tmp.name, "wb") as wf:
        wf.setnchannels(CHANNELS)
        wf.setsampwidth(2)
        wf.setframerate(SAMPLE_RATE)
        wf.writeframes(b"".join(frames))
    return tmp.name


# ---------------------------------------------------------------------------
# STT backends
# ---------------------------------------------------------------------------

def transcribe_sensevoice(wav_path: str) -> str:
    """
    SenseVoiceSmall via FunASR — primary STT.
    Faster than Whisper at this quality tier; adds emotion tag as a bonus.
    Validated by Sparky's pipeline (SenseVoiceSmall on Jetson NX SUPER).
    """
    from funasr import AutoModel
    model = AutoModel(
        model="iic/SenseVoiceSmall",
        trust_remote_code=True,
        device="cuda",
    )
    result = model.generate(
        input=wav_path,
        cache={},
        language="auto",
        use_itn=True,
        batch_size_s=60,
    )
    if result and isinstance(result, list):
        text = result[0].get("text", "")
        # SenseVoice wraps output in emotion tags e.g. <|NEUTRAL|> text <|END|>
        # Strip them for the raw transcript
        import re
        text = re.sub(r"<\|[^|]+\|>", "", text).strip()
        return text
    return ""


def transcribe_whisper(wav_path: str) -> str:
    """faster-whisper base.en — fallback STT."""
    from faster_whisper import WhisperModel
    model = WhisperModel("base.en", device="cuda", compute_type="float16")
    segments, _ = model.transcribe(wav_path, beam_size=1, vad_filter=True)
    return " ".join(s.text.strip() for s in segments).strip()


def transcribe(wav_path: str, backend: str = "sensevoice") -> str:
    if backend == "whisper":
        return transcribe_whisper(wav_path)
    return transcribe_sensevoice(wav_path)


# ---------------------------------------------------------------------------
# TTS
# ---------------------------------------------------------------------------

def speak(text: str):
    voice = os.path.expanduser(
        "~/.local/share/piper/voices/en_GB-alba-medium.onnx"
    )
    if not os.path.exists(voice):
        print(f"[TTS] {text}")
        return
    proc = subprocess.run(
        ["piper", "--model", voice, "--output-raw"],
        input=text.encode(),
        capture_output=True,
    )
    if proc.returncode == 0:
        subprocess.run(
            ["aplay", "-r", "22050", "-f", "S16_LE", "-t", "raw", "-"],
            input=proc.stdout, capture_output=True,
        )
    else:
        print(f"[TTS] {text}")


# ---------------------------------------------------------------------------
# Inference
# ---------------------------------------------------------------------------

def query_ollama(prompt: str, context: str = "") -> str:
    import urllib.request

    full_prompt = f"{context}{prompt}" if context else prompt

    payload = json.dumps({
        "model": OLLAMA_MODEL,
        "prompt": full_prompt,
        "stream": True,
    }).encode()

    req = urllib.request.Request(
        OLLAMA_URL,
        data=payload,
        headers={"Content-Type": "application/json"},
    )
    full = ""
    with urllib.request.urlopen(req) as resp:
        for line in resp:
            chunk = json.loads(line.decode())
            token = chunk.get("response", "")
            full += token
            print(token, end="", flush=True)
            if chunk.get("done"):
                break
    print()
    return full


# ---------------------------------------------------------------------------
# Main pipeline
# ---------------------------------------------------------------------------

def run_query(transcript: str, stt_backend: str, no_tts: bool, no_context: bool):
    if not transcript.strip():
        print("Nothing heard.")
        return

    context = "" if no_context else get_machine_context()
    if context:
        print(f"\n[ctx] {context.splitlines()[1]}")  # show first context line

    print("Assistant: ", end="", flush=True)
    response = query_ollama(transcript, context=context)
    if not no_tts:
        speak(response)


def main():
    parser = argparse.ArgumentParser(description="Cyberdeck voice query pipeline")
    parser.add_argument("--push-to-talk", action="store_true")
    parser.add_argument("--wake-word",    action="store_true")
    parser.add_argument("--pipe",         type=str, help="Skip STT, use this text")
    parser.add_argument("--stt",          type=str, default="sensevoice",
                        choices=["sensevoice", "whisper"],
                        help="STT backend (default: sensevoice)")
    parser.add_argument("--no-tts",       action="store_true")
    parser.add_argument("--no-context",   action="store_true",
                        help="Skip machine state context injection")
    args = parser.parse_args()

    if args.pipe:
        run_query(args.pipe, args.stt, args.no_tts, args.no_context)
        return

    if args.wake_word:
        _run_wake_word_loop(args.stt, args.no_tts, args.no_context)
        return

    if args.push_to_talk:
        frames = record_push_to_talk()
    else:
        frames = record_with_vad()

    wav = frames_to_wav(frames)
    print("Transcribing...", end="", flush=True)
    t0 = time.monotonic()
    transcript = transcribe(wav, backend=args.stt)
    os.unlink(wav)
    print(f" {(time.monotonic()-t0)*1000:.0f}ms\nYou: {transcript}")

    run_query(transcript, args.stt, args.no_tts, args.no_context)


def _run_wake_word_loop(stt_backend: str, no_tts: bool, no_context: bool):
    import pvporcupine
    import pvrecorder

    key_path = os.path.expanduser("~/.config/porcupine.env")
    access_key = ""
    if os.path.exists(key_path):
        for line in open(key_path):
            if line.startswith("PORCUPINE_ACCESS_KEY="):
                access_key = line.split("=", 1)[1].strip()

    if not access_key:
        print("ERROR: Set PORCUPINE_ACCESS_KEY in ~/.config/porcupine.env")
        sys.exit(1)

    porcupine = pvporcupine.create(access_key=access_key, keywords=["hey google"])
    recorder  = pvrecorder.PvRecorder(frame_length=porcupine.frame_length)
    recorder.start()
    print(f"Wake word active (STT: {stt_backend}). Say 'Hey Google' to query.")

    try:
        while True:
            pcm = recorder.read()
            if porcupine.process(pcm) >= 0:
                print("\nWake word detected!")
                recorder.stop()
                frames = record_with_vad()
                wav = frames_to_wav(frames)
                print("Transcribing...", end="", flush=True)
                t0 = time.monotonic()
                transcript = transcribe(wav, backend=stt_backend)
                os.unlink(wav)
                print(f" {(time.monotonic()-t0)*1000:.0f}ms\nYou: {transcript}")
                run_query(transcript, stt_backend, no_tts, no_context)
                recorder.start()
                print("\nListening...")
    except KeyboardInterrupt:
        pass
    finally:
        recorder.delete()
        porcupine.delete()


if __name__ == "__main__":
    main()
PYEOF
chmod +x ~/.local/bin/voice-query

echo "==> Adding audio aliases to bash config"
cat >> ~/.config/bash/aliases <<'EOF'

# Voice pipeline (Sparky-inspired: Hear→Transcribe→Context→Think→Speak)
alias vq='voice-query --push-to-talk'              # push-to-talk, sensevoice STT
alias vqw='voice-query'                            # VAD auto-stop
alias vw='voice-query --wake-word'                 # always-on wake word
alias vqf='voice-query --stt whisper'              # faster-whisper fallback
alias tts='piper --model ~/.local/share/piper/voices/en_GB-alba-medium.onnx --output-raw | aplay -r 22050 -f S16_LE -t raw -'
EOF

echo "==> Creating systemd user service for wake word daemon (optional)"
mkdir -p ~/.config/systemd/user
cat > ~/.config/systemd/user/cyberdeck-voice.service <<'EOF'
[Unit]
Description=Cyberdeck wake word listener
After=pulseaudio.service

[Service]
ExecStart=/usr/bin/python3 /home/%i/.local/bin/voice-query --wake-word --no-tts
Restart=on-failure
RestartSec=5

[Install]
WantedBy=default.target
EOF
echo "    Enable with: systemctl --user enable --now cyberdeck-voice"

echo ""
echo "==> Audio stack installed."
echo ""
echo "    Pipeline: Hear → Transcribe → [machine context] → Think → Speak"
echo ""
echo "    STT (primary):  SenseVoiceSmall (FunASR, CUDA) — ~245MB, emotion detection"
echo "    STT (fallback): faster-whisper base.en (CUDA)  — ~290MB, --stt whisper"
echo "    TTS:            Piper en_GB-alba-medium         — ~150ms CPU"
echo "    VAD:            Silero                          — auto end-of-speech"
echo "    Wake:           Porcupine → ~/.config/porcupine.env"
echo ""
echo "    Context injected per query:"
echo "      time, power mode, system draw, Reticulum mesh, loaded models, tmux sessions"
echo ""
echo "    Aliases:"
echo "      vq   — push-to-talk → Ollama"
echo "      vqw  — VAD auto-stop → Ollama"
echo "      vw   — wake word always-on"
echo "      vqf  — push-to-talk, whisper backend"
echo "      tts  — pipe text to speech"
echo ""
echo "    Memory: SenseVoice ~245MB + Llama 3B ~2GB + OS ~400MB ≈ 2.7GB of 8GB"
