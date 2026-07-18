# Ollama — Common Failures & Reference

## Quick Reference

```bash
ollama list                          # list downloaded models
ollama ps                            # show loaded models (GPU usage)
ollama pull llama3.2:3b-instruct-q4_K_M   # pull a model
ollama rm <model>                    # remove a model
ollama run llama3.2:3b-instruct-q4_K_M    # interactive session
ollama serve                         # start server (auto-started by systemd)

# API
curl http://localhost:11434/api/generate -d '{
  "model": "llama3.2:3b-instruct-q4_K_M",
  "prompt": "Hello",
  "stream": false
}'
curl http://localhost:11434/api/ps    # loaded models + GPU memory
```

## Common Failures

### Ollama not starting / port 11434 not open

**Symptom:** `curl http://localhost:11434` fails.

**Fix:**
```bash
systemctl status ollama              # check service
systemctl restart ollama             # restart
journalctl -u ollama -f              # follow logs
```

---

### Model loads on CPU instead of GPU

**Symptom:** Inference very slow, `ollama ps` shows 0 GPU memory.

**Cause A:** CUDA not available to Ollama. Check:
```bash
ollama run llama3.2:3b --verbose    # shows device in output
```

**Cause B:** Model too large for VRAM — partially offloaded to CPU.
On Orin Nano 8GB (unified RAM), check total usage:
```bash
sudo jtop    # watch MEM row — RAM shared between CPU and GPU
```

**Fix:** Use a smaller or more quantised model:
```bash
# q4_K_M is the best quality/size tradeoff for 3B
ollama pull llama3.2:3b-instruct-q4_K_M   # ~2GB
```

---

### CUDA out of memory after multiple models loaded

**Symptom:** New model fails to load, existing models still running.

**Cause:** Ollama keeps models in VRAM after use. Default timeout is 5min.

**Fix:** Unload idle models:
```bash
# Unload a specific model:
ollama stop llama3.2:3b-instruct-q4_K_M

# Or reduce keepalive timeout in /etc/systemd/system/ollama.service:
# Environment="OLLAMA_KEEP_ALIVE=1m"
```

---

### First inference very slow (cold start)

**Symptom:** First query takes 30+ seconds, subsequent queries fast.

**Cause:** Model loading from NVMe to VRAM on first use. Normal behaviour.

**Fix for demos:** Pre-load with a dummy query on startup:
```bash
# In /etc/systemd/system/ollama.service or startup script:
curl -s http://localhost:11434/api/generate -d \
  '{"model":"llama3.2:3b-instruct-q4_K_M","prompt":"hi","stream":false}' \
  > /dev/null &
```

---

### Context length errors

**Symptom:** `context length exceeded` error for long conversations.

**Cause:** Default context window is model-dependent (usually 2048-8192 tokens).

**Fix:** Set num_ctx explicitly:
```bash
curl http://localhost:11434/api/generate -d '{
  "model": "llama3.2:3b-instruct-q4_K_M",
  "prompt": "...",
  "options": {"num_ctx": 4096}
}'
```

## Model reference

| Model | Size | Use case |
|---|---|---|
| `llama3.2:3b-instruct-q4_K_M` | ~2GB | Primary — fast, good quality |
| `nomic-embed-text` | ~270MB | Embeddings for semantic cache |
| `llama3.2:1b-instruct-q4_K_M` | ~1GB | Ultra-fast, lower quality |
