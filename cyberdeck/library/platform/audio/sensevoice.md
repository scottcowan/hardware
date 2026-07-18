# SenseVoiceSmall — Troubleshooting & Reference

Primary STT engine for the cyberdeck. FunASR model, CUDA-accelerated.

## Common Failures

### Illegal instruction / SIGILL on load

**Symptom:** Python crashes with `Illegal instruction` when loading model.

**Cause:** ONNX Runtime built for AVX2 running on non-AVX2 CPU. Jetson
Orin Nano's A78AE supports NEON but not AVX2.

**Fix:** Install FunASR with the ARM-native ONNX Runtime:
```bash
pip3 install onnxruntime   # ARM build, not onnxruntime-gpu
pip3 install funasr
```

---

### CUDA OOM on first load

**Symptom:** `RuntimeError: CUDA out of memory` when model loads.

**Cause:** Model loaded at float32 before quantisation. SenseVoiceSmall
is ~245MB but float32 intermediates spike higher.

**Fix:** Force int8 quantisation:
```python
model = AutoModel(
    model="iic/SenseVoiceSmall",
    device="cuda",
    fp16=True,        # use fp16 not fp32
    trust_remote_code=True,
)
```

---

### Model download fails / hangs

**Symptom:** `AutoModel()` hangs or fails during first-run download.

**Fix:** Download manually from ModelScope:
```bash
pip3 install modelscope
python3 -c "
from modelscope import snapshot_download
snapshot_download('iic/SenseVoiceSmall')
"
```

---

### Output contains raw emotion tags

**Symptom:** Transcript includes `<|NEUTRAL|>` or `<|HAPPY|>` tags.

**Cause:** SenseVoice wraps output in emotion/event tags by design.

**Fix:** Strip with regex (already in voice-query pipeline):
```python
import re
text = re.sub(r'<\|[^|]+\|>', '', result[0]['text']).strip()
```

## Reference

```python
from funasr import AutoModel

model = AutoModel(
    model="iic/SenseVoiceSmall",
    trust_remote_code=True,
    device="cuda",        # or "cpu"
)

result = model.generate(
    input="recording.wav",
    cache={},
    language="auto",      # or "en", "zh", "ja", "ko", "yue"
    use_itn=True,         # inverse text normalisation (numbers, dates)
    batch_size_s=60,
)
text = result[0]['text']
```

## Memory footprint

- Model: ~245MB VRAM on CUDA
- Inference: ~350MB peak (fp16)
- CPU fallback: ~500MB RAM
