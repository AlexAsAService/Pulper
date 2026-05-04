# =============================================================================
# Pulper — Containerized Document-to-Markdown Conversion
# =============================================================================
# Build targets:
#   minimal-no-shim  — Core MarkItDown + Go Classifier (direct binary)
#   minimal-shim     — Core MarkItDown + Go Classifier (w/ UID/GID mapping)
#   full-no-shim     — Adds FFmpeg/Office/OCR (direct binary)
#   full-shim        — Adds FFmpeg/Office/OCR (w/ UID/GID mapping)
# =============================================================================

# ---------------------------------------------------------------------------
# Stage 1: Build the Go Classifier
# ---------------------------------------------------------------------------
FROM golang:1.26-alpine AS go-builder
WORKDIR /build
COPY ./cmd ./cmd
COPY go.mod ./
RUN go build -o classifier ./cmd/classifier

# ---------------------------------------------------------------------------
# Stage 2: Base Python Environment
# ---------------------------------------------------------------------------
FROM python:3.12-slim AS base

# Python & Pip Configuration:
# - PYTHONDONTWRITEBYTECODE: Prevent .pyc files (keep image clean)
# - PYTHONUNBUFFERED: Real-time logging (no stdout/stderr buffering)
# - PIP_NO_CACHE_DIR: Reduce image size by skipping pip cache
# - PIP_DISABLE_PIP_VERSION_CHECK: Silence noisy update warnings
# - ORT_LOGGING_LEVEL: Silence ONNX hardware discovery warnings (Level 3 = ERROR)
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    ORT_LOGGING_LEVEL=3 \
    PATH="/usr/local/bin:$PATH"

# Install shared runtime dependencies (ffmpeg is needed by markitdown)
RUN apt-get update && apt-get install -y --no-install-recommends \
    ffmpeg \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy the classifier binary to a common location
COPY --from=go-builder /build/classifier /usr/local/bin/classifier
RUN chmod +x /usr/local/bin/classifier

# ---------------------------------------------------------------------------
# Stage 3: Minimal Foundation
# ---------------------------------------------------------------------------
FROM base AS minimal-foundation
# (Already contains MarkItDown via pip and the Classifier binary)

# ---------------------------------------------------------------------------
# Stage 4: Full Foundation (with heavy dependencies)
# ---------------------------------------------------------------------------
FROM minimal-foundation AS full-foundation
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

# =============================================================================
# Final Production Targets
# =============================================================================

# --- TARGET: minimal-no-shim ---
FROM minimal-foundation AS minimal-no-shim
RUN groupadd -g 9999 pulper && \
    useradd -u 9999 -g pulper -s /bin/bash -m pulper
USER pulper
ENTRYPOINT ["classifier"]
CMD ["--help"]

# --- TARGET: minimal-shim ---
FROM minimal-foundation AS minimal-shim
RUN apt-get update && apt-get install -y --no-install-recommends gosu && rm -rf /var/lib/apt/lists/*
COPY scripts/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh
ENTRYPOINT ["entrypoint.sh"]
CMD ["--help"]

# --- TARGET: full-no-shim ---
FROM full-foundation AS full-no-shim
RUN groupadd -g 9999 pulper && \
    useradd -u 9999 -g pulper -s /bin/bash -m pulper
USER pulper
ENTRYPOINT ["classifier"]
CMD ["--help"]

# --- TARGET: full-shim ---
FROM full-foundation AS full-shim
RUN apt-get update && apt-get install -y --no-install-recommends gosu && rm -rf /var/lib/apt/lists/*
COPY scripts/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh
ENTRYPOINT ["entrypoint.sh"]
CMD ["--help"]
