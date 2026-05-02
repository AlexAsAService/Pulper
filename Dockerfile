# =============================================================================
# Pulper — Containerized Document-to-Markdown Conversion
# =============================================================================
# Build targets:
#   minimal  — core MarkItDown conversion only
#   full     — extended with optional native deps (OCR, audio, etc.)
#
# Usage:
#   docker build --target minimal -t pulper:minimal .
#   docker build --target full    -t pulper:full    .
# =============================================================================

# ---------------------------------------------------------------------------
# Base stage — shared foundation
# ---------------------------------------------------------------------------
# Allow swapping the base image (e.g., for Distroless in prod)
ARG BASE_IMAGE=python:3.12-slim
FROM ${BASE_IMAGE} AS base

# Metadata
LABEL org.opencontainers.image.title="Pulper" \
      org.opencontainers.image.description="Containerized document-to-Markdown conversion via MarkItDown" \
      org.opencontainers.image.source="https://github.com/AlexAsAService/Pulper"

# Reproducible installs — no cache pollution
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

# Build-time identity for volume permissions (defaults to 1001)
ARG USER_ID=1001
ARG GROUP_ID=1001

# Non-root user for safe execution
RUN groupadd --gid ${GROUP_ID} pulper \
 && useradd  --uid ${USER_ID} --gid pulper --shell /bin/bash --create-home pulper

# Install system runtime dependencies and gosu for the shim stage
RUN apt-get update && apt-get install -y --no-install-recommends \
    ffmpeg \
    gosu \
    && rm -rf /var/lib/apt/lists/*

COPY scripts/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

WORKDIR /app
ENTRYPOINT ["entrypoint.sh", "markitdown"]

# ---------------------------------------------------------------------------
# deps — builder stage
# ---------------------------------------------------------------------------
FROM base AS deps

COPY requirements.txt ./
RUN pip install -r requirements.txt

# ---------------------------------------------------------------------------
# minimal — production-ready rootless stage
# ---------------------------------------------------------------------------
FROM base AS minimal

COPY --from=deps /usr/local/lib/python3.12/site-packages /usr/local/lib/python3.12/site-packages
COPY --from=deps /usr/local/bin /usr/local/bin

# Input is always read-only source material; output is the artifact directory
VOLUME ["/input", "/output"]

USER pulper

CMD ["--help"]

# ---------------------------------------------------------------------------
# full — extended image with optional native dependencies (OCR, Office)
# ---------------------------------------------------------------------------
FROM minimal AS full

USER root

# Install LibreOffice (Headless) and Tesseract OCR
RUN apt-get update && apt-get install -y --no-install-recommends \
    libreoffice-writer \
    libreoffice-calc \
    libreoffice-impress \
    python3-uno \
    tesseract-ocr \
    tesseract-ocr-eng \
    libmagic1 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

USER pulper

# ---------------------------------------------------------------------------
# shim — "It just works" stage with automatic UID/GID mapping
# ---------------------------------------------------------------------------
FROM full AS shim

USER root
# (Inherits entrypoint and logic from base)
CMD ["--help"]
