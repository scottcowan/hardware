#!/bin/bash
# Audio stack for Jetson Orin Nano cyberdeck
# STT: faster-whisper (CUDA), TTS: Piper, VAD: Silero, Wake word: Porcupine
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

echo "==> Installing faster-whisper (CUDA-accelerated STT)"
pip3 install faster-whisper

echo "==> Pre-downloading Whisper base.en model"
python3 - <<'PYEOF'
from faster_whisper import WhisperModel
print("Downloading whisper base.en model...")
model = WhisperModel("base.en", device="cuda", compute_type="float16")
print("Model ready.")
PYEOF

echo "==> Installing Silero VAD"
pip3 install silero-vad

echo "==> Installing Piper TTS"
pip3 install piper-tts

echo "==> Downloading Piper voice (en_GB-alba-medium — clear British female)"
mkdir -p ~/.local/share/piper/voices
cd ~/.local/share/piper/voices
# Alba voice — clear, neutral, works well for terminal readback
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
# Free tier supports 1 wake word, non-commercial use
PORCUPINE_ACCESS_KEY=
EOF
echo "    NOTE: Add your Porcupine access key to ~/.config/porcupine.env"
echo "    Get a free key at: https://console.picovoice.ai/"

echo "==> Writing voice pipeline script (~/.local/bin/voice-query)"
mkdir -p ~/.local/bin
cat > ~/.local/bin/voice-query <<'PYEOF'
#!/usr/bin/env python3
"""
Cyberdeck voice query pipeline.
Hold-to-speak: run with --push-to-talk
Always-on:     run with --wake-word (requires Porcupine key)

Usage:
  voice-query --push-to-talk        # press Enter to start/stop recording
  voice-query --wake-word           # say "Hey Google" (or custom word)
  voice-query --pipe "some text"    # skip STT, pipe text directly to Ollama
"""

import argparse
import subprocess
import sys
import tempfile
import os
import wave
import struct
import time

import pyaudio
import numpy as np
from faster_whisper import WhisperModel
from silero_vad import load_silero_vad, get_speech_timestamps

SAMPLE_RATE = 16000
CHANNELS = 1
CHUNK = 512
VAD_THRESHOLD = 0.5
SILENCE_DURATION = 0.8  # seconds of silence before stopping

def record_push_to_talk():
    """Record until user presses Enter."""
    pa = pyaudio.PyAudio()
    stream = pa.open(format=pyaudio.paInt16, channels=CHANNELS,
                     rate=SAMPLE_RATE, input=True, frames_per_buffer=CHUNK)
    frames = []
    print("Recording... (press Enter to stop)", end="", flush=True)
    import threading
    stop_event = threading.Event()
    def wait_enter():
        input()
        stop_event.set()
    threading.Thread(target=wait_enter, daemon=True).start()
    while not stop_event.is_set():
        frames.append(stream.read(CHUNK, exception_on_overflow=False))
    stream.stop_stream()
    stream.close()
    pa.terminate()
    return frames

def record_with_vad():
    """Record with Silero VAD — stops after SILENCE_DURATION of silence."""
    model = load_silero_vad()
    pa = pyaudio.PyAudio()
    stream = pa.open(format=pyaudio.paInt16, channels=CHANNELS,
                     rate=SAMPLE_RATE, input=True, frames_per_buffer=CHUNK)
    frames = []
    silent_chunks = 0
    speaking_started = False
    silence_chunks_needed = int(SILENCE_DURATION * SAMPLE_RATE / CHUNK)

    print("Listening...", end="", flush=True)
    while True:
        data = stream.read(CHUNK, exception_on_overflow=False)
        frames.append(data)
        audio_chunk = np.frombuffer(data, dtype=np.int16).astype(np.float32) / 32768.0
        import torch
        tensor = torch.from_numpy(audio_chunk)
        speech_prob = model(tensor, SAMPLE_RATE).item()

        if speech_prob > VAD_THRESHOLD:
            speaking_started = True
            silent_chunks = 0
            print(".", end="", flush=True)
        elif speaking_started:
            silent_chunks += 1
            if silent_chunks >= silence_chunks_needed:
                break

    print()
    stream.stop_stream()
    stream.close()
    pa.terminate()
    return frames

def frames_to_wav(frames):
    """Write frames to a temp WAV file, return path."""
    tmp = tempfile.NamedTemporaryFile(suffix=".wav", delete=False)
    with wave.open(tmp.name, "wb") as wf:
        wf.setnchannels(CHANNELS)
        wf.setsampwidth(2)  # 16-bit
        wf.setframerate(SAMPLE_RATE)
        wf.writeframes(b"".join(frames))
    return tmp.name

def transcribe(wav_path):
    """Transcribe WAV using faster-whisper on CUDA."""
    model = WhisperModel("base.en", device="cuda", compute_type="float16")
    segments, _ = model.transcribe(wav_path, beam_size=1, vad_filter=True)
    text = " ".join(s.text.strip() for s in segments).strip()
    return text

def speak(text):
    """Speak text using Piper TTS."""
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
            input=proc.stdout,
            capture_output=True,
        )
    else:
        print(f"[TTS] {text}")

def query_ollama(prompt):
    """Send prompt to Ollama and stream response."""
    import urllib.request
    import json
    payload = json.dumps({
        "model": "llama3.2:3b-instruct-q4_K_M",
        "prompt": prompt,
        "stream": True,
    }).encode()
    req = urllib.request.Request(
        "http://localhost:11434/api/generate",
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

def main():
    parser = argparse.ArgumentParser(description="Cyberdeck voice query")
    parser.add_argument("--push-to-talk", action="store_true")
    parser.add_argument("--wake-word", action="store_true")
    parser.add_argument("--pipe", type=str, help="Skip STT, use this text")
    parser.add_argument("--no-tts", action="store_true", help="Skip TTS output")
    args = parser.parse_args()

    if args.pipe:
        transcript = args.pipe
    elif args.push_to_talk:
        frames = record_push_to_talk()
        wav = frames_to_wav(frames)
        print("Transcribing...", end="", flush=True)
        transcript = transcribe(wav)
        os.unlink(wav)
        print(f" Done.\nYou: {transcript}")
    elif args.wake_word:
        _run_wake_word_loop(args.no_tts)
        return
    else:
        frames = record_with_vad()
        wav = frames_to_wav(frames)
        print("Transcribing...", end="", flush=True)
        transcript = transcribe(wav)
        os.unlink(wav)
        print(f" Done.\nYou: {transcript}")

    if not transcript:
        print("Nothing heard.")
        return

    print("Assistant: ", end="", flush=True)
    response = query_ollama(transcript)

    if not args.no_tts:
        speak(response)

def _run_wake_word_loop(no_tts=False):
    """Continuous wake word detection loop using Porcupine."""
    import pvporcupine
    import pvrecorder

    dotenv_path = os.path.expanduser("~/.config/porcupine.env")
    access_key = ""
    if os.path.exists(dotenv_path):
        for line in open(dotenv_path):
            if line.startswith("PORCUPINE_ACCESS_KEY="):
                access_key = line.split("=", 1)[1].strip()

    if not access_key:
        print("ERROR: Set PORCUPINE_ACCESS_KEY in ~/.config/porcupine.env")
        sys.exit(1)

    porcupine = pvporcupine.create(
        access_key=access_key,
        keywords=["hey google"],  # free built-in keyword
    )
    recorder = pvrecorder.PvRecorder(frame_length=porcupine.frame_length)
    recorder.start()
    print("Wake word active. Say 'Hey Google' to start a query.")

    try:
        while True:
            pcm = recorder.read()
            result = porcupine.process(pcm)
            if result >= 0:
                print("\nWake word detected!")
                recorder.stop()
                frames = record_with_vad()
                wav = frames_to_wav(frames)
                print("Transcribing...", end="", flush=True)
                transcript = transcribe(wav)
                os.unlink(wav)
                print(f" Done.\nYou: {transcript}")
                if transcript:
                    print("Assistant: ", end="", flush=True)
                    response = query_ollama(transcript)
                    if not no_tts:
                        speak(response)
                recorder.start()
                print("\nListening for wake word...")
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

# Voice pipeline
alias vq='voice-query --push-to-talk'     # push-to-talk query
alias vw='voice-query --wake-word'         # always-on wake word mode
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
Environment=DISPLAY=:0

[Install]
WantedBy=default.target
EOF
echo "    Enable wake word daemon with: systemctl --user enable --now cyberdeck-voice"

echo ""
echo "==> Audio stack installed."
echo ""
echo "    STT:   faster-whisper base.en (CUDA) — ~0.3s for 10s clip"
echo "    TTS:   Piper en_GB-alba-medium — ~150ms latency, runs on CPU"
echo "    VAD:   Silero — auto end-of-speech detection"
echo "    Wake:  Porcupine — add key to ~/.config/porcupine.env"
echo ""
echo "    Usage:"
echo "      vq              — push-to-talk voice query → Ollama"
echo "      vw              — wake word always-on mode"
echo "      echo 'hello' | tts  — pipe text to speech"
echo "      voice-query --pipe 'what is the weather' — skip mic"
echo ""
echo "    Memory footprint:"
echo "      Whisper base.en: ~290MB VRAM (CUDA)"
echo "      Piper:           ~50MB CPU (loaded on demand)"
echo "      Silero VAD:      ~15MB"
echo "      All three + Llama 3B + OS: ~3GB of 8GB — comfortable"
