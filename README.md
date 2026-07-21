# Fish Speech (S2-Pro) — RunPod Template

Auto-installing Docker image for `benjiyaya/fish-speech` (fork of Fish Audio's
S2-Pro with a built-in Whisper auto-transcription button for voice cloning).

On first boot the container downloads the S2-Pro weights (≈4B params) and a
Whisper model into RunPod's persistent `/workspace` volume, then launches the
Gradio WebUI on port 7860. On later restarts (same volume) it skips the
downloads and starts immediately.

## 1. Build & push the image

```bash
docker build -t <your-dockerhub-user>/fish-speech-runpod:latest .
docker push <your-dockerhub-user>/fish-speech-runpod:latest
```

(Or point RunPod at a GitHub-connected build if you prefer not to push manually.)

## 2. Create the RunPod Template

In RunPod console → Templates → New Template:

| Field | Value |
|---|---|
| Container Image | `<your-dockerhub-user>/fish-speech-runpod:latest` |
| Container Disk | 20 GB+ |
| Volume Disk | 30 GB+ (holds the checkpoints so they persist across restarts) |
| Volume Mount Path | `/workspace` |
| Expose HTTP Ports | `7860` |
| Expose TCP Ports | `22` (optional, for SSH) |

### Environment variables (optional overrides)

| Var | Default | Purpose |
|---|---|---|
| `WHISPER_MODEL` | `small` | Whisper model size for auto-transcription (`tiny`/`base`/`small`/`medium`/`large`) |
| `PUBLIC_KEY` | — | Paste your SSH public key to enable SSH into the pod |
| `HF_TOKEN` | — | Set if `fishaudio/s2-pro` ever requires authentication |

## 3. Deploy a GPU pod from the template

Pick a GPU with ≥16GB VRAM (S2-Pro is a 4B model; an RTX 4090 / A40 / L40S / A100 all work fine). Launch the pod, wait for the first-boot download (a few minutes depending on network speed), then open the pod's HTTP port 7860 from the RunPod dashboard — that's your WebUI.

## Notes

- Weights land in `/workspace/checkpoints/s2-pro` and `/workspace/checkpoints/whisper-small-pt`, both on the persistent volume — stopping/restarting the pod won't re-trigger the download.
- The template pins `REPO_REF=main` at build time (see `Dockerfile` `ARG`s). Pass `--build-arg REPO_REF=<commit-sha>` at build time if you want a reproducible, non-moving image instead of always tracking `main`.
- This fork's code and the S2-Pro weights are distributed under the **Fish Audio Research License** — review it before any commercial use.
