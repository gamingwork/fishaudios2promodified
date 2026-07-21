# =========================================================
# RunPod template: benjiyaya/fish-speech (Fish Audio S2-Pro)
# Gradio WebUI + Whisper auto-transcription, auto-downloads
# model weights into the persistent /workspace volume on
# first boot.
# =========================================================

FROM nvidia/cuda:12.6.0-cudnn-runtime-ubuntu24.04

ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1

# ---- System deps -------------------------------------------------
RUN apt-get update && apt-get install -y --no-install-recommends \
        git curl wget aria2 ca-certificates \
        python3 python3-pip python3-venv python3-dev \
        build-essential cmake \
        ffmpeg libsm6 libxext6 libjpeg-dev zlib1g-dev \
        libsox-dev libasound-dev portaudio19-dev libportaudio2 libportaudiocpp0 \
        openssh-server \
    && ln -sf /usr/bin/python3 /usr/bin/python \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# ---- uv (fast python package manager, matches upstream repo) -----
COPY --from=ghcr.io/astral-sh/uv:0.8.15 /uv /uvx /bin/

WORKDIR /app

# ---- Clone the fork ------------------------------------------------
ARG REPO_URL=https://github.com/benjiyaya/fish-speech.git
ARG REPO_REF=main
RUN git clone --depth 1 --branch ${REPO_REF} ${REPO_URL} . \
    || (git clone ${REPO_URL} . && git checkout ${REPO_REF})

# ---- Python deps ---------------------------------------------------
RUN uv python pin 3.12 \
    && uv sync --extra cu126 --frozen --no-install-project || uv sync --extra cu126
RUN uv sync --extra cu126

# Extra deps used by the WebUI + Whisper auto-transcription feature
RUN uv pip install --system -r requirements.txt \
    && uv pip install --system huggingface_hub[cli] hf_transfer

# ---- Runtime env ----------------------------------------------------
ENV HF_HUB_ENABLE_HF_TRANSFER=1 \
    GRADIO_SERVER_NAME=0.0.0.0 \
    GRADIO_SERVER_PORT=7860 \
    LLAMA_CHECKPOINT_PATH=/workspace/checkpoints/s2-pro \
    DECODER_CHECKPOINT_PATH=/workspace/checkpoints/s2-pro/codec.pth \
    DECODER_CONFIG_NAME=modded_dac_vq \
    WHISPER_MODEL_DIR=/workspace/checkpoints/whisper-small-pt \
    WHISPER_MODEL=small

EXPOSE 7860 22

COPY start.sh /app/start.sh
RUN chmod +x /app/start.sh

ENTRYPOINT ["/app/start.sh"]
