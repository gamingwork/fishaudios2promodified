#!/bin/bash
set -euo pipefail

log() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*"; }

if [ -n "${PUBLIC_KEY:-}" ]; then
    log "Setting up SSH access..."
    mkdir -p ~/.ssh
    echo "${PUBLIC_KEY}" >> ~/.ssh/authorized_keys
    chmod 700 ~/.ssh && chmod 600 ~/.ssh/authorized_keys
    service ssh start || (mkdir -p /run/sshd && /usr/sbin/sshd)
fi

mkdir -p /workspace/checkpoints /workspace/references

S2_DIR="/workspace/checkpoints/s2-pro"
if [ ! -f "${S2_DIR}/codec.pth" ]; then
    log "S2-Pro checkpoint not found, downloading from HuggingFace (fishaudio/s2-pro)..."
    huggingface-cli download fishaudio/s2-pro --local-dir "${S2_DIR}"
else
    log "S2-Pro checkpoint already present, skipping download."
fi

WHISPER_DIR="${WHISPER_MODEL_DIR:-/workspace/checkpoints/whisper-small-pt}"
if [ ! -d "${WHISPER_DIR}" ] || [ -z "$(ls -A "${WHISPER_DIR}" 2>/dev/null)" ]; then
    log "Downloading Whisper model (${WHISPER_MODEL:-small})..."
    mkdir -p "${WHISPER_DIR}"
    python - <<PYEOF
import whisper, os
whisper.load_model(os.environ.get("WHISPER_MODEL", "small"), download_root=os.environ.get("WHISPER_MODEL_DIR"))
PYEOF
else
    log "Whisper model already present, skipping download."
fi

log "Starting Fish Speech WebUI on ${GRADIO_SERVER_NAME}:${GRADIO_SERVER_PORT}..."
cd /app
exec uv run tools/run_webui.py \
    --llama-checkpoint-path "${LLAMA_CHECKPOINT_PATH}" \
    --decoder-checkpoint-path "${DECODER_CHECKPOINT_PATH}" \
    --decoder-config-name "${DECODER_CONFIG_NAME}" \
    --whisper-model-dir "${WHISPER_MODEL_DIR}" \
    --device cuda \
    "$@"
