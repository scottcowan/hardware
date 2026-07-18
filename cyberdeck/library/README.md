# Cyberdeck Local Library

Platform-adjacent runbooks and troubleshooting guides for offline use.
Ingested into the cyberharness semantic cache — answers common queries
without touching the Beyond.

## Philosophy

Stock the ship before you sail. The highest-value content is what you
need at 2am offline when something breaks. Curated, not comprehensive.
Symptom→cause→fix format throughout.

## Structure

```
library/
  platform/
    jetson/       — JetPack, nvpmodel, CUDA, GPIO, common failures
    linux/        — systemd, networking, storage, permissions
    reticulum/    — rnsd, RNode, NomadNet
    ollama/       — model management, CUDA issues, API reference
    audio/        — ALSA, Piper, SenseVoice
```

## Ingest

```bash
cyberharness library ingest ~/.cyberharness/library/
cyberharness library ingest ./cyberdeck/library/    # from this repo
```

## Contributing

Add a new doc: `platform/<subsystem>/<topic>.md`
Format: symptom→cause→fix for troubleshooting, reference for API/config docs.
Keep each doc focused — one subsystem, one topic.
