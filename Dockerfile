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

# Reproducible installs — no cache pollution
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

# Install system runtime dependencies and gosu for the shim stage
RUN apt-get update && apt-get install -y --no-install-recommends \
    gosu \
    && rm -rf /var/lib/apt/lists/*

# Build-time identity for volume permissions (defaults to 1001)
# Don't we want to default to something less likely to overlap with a real user on the host?
ARG USER_ID=1001
ARG GROUP_ID=1001

# Non-root user for safe execution
RUN groupadd --gid ${GROUP_ID} pulper \
 && useradd  --uid ${USER_ID} --gid pulper --shell /bin/bash --create-home pulper

# Metadata
LABEL org.opencontainers.image.title="Pulper" \
      org.opencontainers.image.description="Containerized document-to-Markdown conversion via MarkItDown" \
      org.opencontainers.image.source="https://github.com/AlexAsAService/Pulper"

WORKDIR /app


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

COPY scripts/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

USER pulper

# We should have a minimal entrypoint here cause we don't need to do transpilations
ENTRYPOINT ["entrypoint.sh", "markitdown"]
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
    ffmpeg \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# We should have a full version of the entrypoint script here with the logic to transpile
COPY scripts/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

USER pulper

ENTRYPOINT ["entrypoint.sh", "markitdown"]


# ---------------------------------------------------------------------------
# shim — "It just works" stage with automatic UID/GID mapping
# ---------------------------------------------------------------------------
# We aren't offering non-shim version anymore so this is superfluous at this point
# Maybe we should come back to this and rework to where we can build non-shim versions again
FROM full AS shim

USER root
# (Inherits entrypoint and logic from base)
CMD ["--help"]
