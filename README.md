# 🧺 Pulper

**Professional, containerized document-to-Markdown conversion.**

Pulper is a containerization of Microsoft [MarkItDown](https://github.com/microsoft/markitdown), designed to turn complex source documents into clean, AI-ready Markdown. It abstracts away the dependency requirements for OCR, media processing, and document transpilation into a portable CLI interface.

---

## 🚀 Capabilities

Pulper provides a unified interface for converting a wide range of document types. To ensure reliable conversion, it uses a classifier written in Go to preprocess inputs before handing them to the MarkItDown engine.

### Supported Formats
- **Modern Formats**: Native support for `.docx`, `.pptx`, `.xlsx`, `.pdf`, `.html`, `.csv`, `.json`, `.txt`, and `.zip` archives.
- **Legacy Documents**: Automatic conversion of `.doc`, `.odt`, `.rtf`, `.ods`, `.ppt`, and `.odp` via an internal LibreOffice runtime.
- **Audio Normalization**: Automatic processing of `.wav`, `.mp3`, `.m4a`, `.flac`, and `.ogg` via FFmpeg (standardized to 16kHz mono for optimal ingestion).

### How it works
When you pass a file to Pulper, the internal classifier identifies the file type. If it's a legacy or media format that MarkItDown doesn't natively support, Pulper automatically transpiles it into a modern equivalent (like `.docx` or normalized `.wav`) in a temporary scratch space before final conversion.

---

## 📥 Where to Download

Images are hosted on the GitHub Container Registry (GHCR).

| Variant | Repository | Tag |
| :--- | :--- | :--- |
| **Pulper (Full)** | [ghcr.io/alexasaservice/pulper](https://ghcr.io/alexasaservice/pulper) | `latest` |
| **Pulper (Full, No-Shim)** | [ghcr.io/alexasaservice/pulper](https://ghcr.io/alexasaservice/pulper) | `latest-no-shim` |
| **Pulper-Lite** | [ghcr.io/alexasaservice/pulper-lite](https://ghcr.io/alexasaservice/pulper-lite) | `latest` |
| **Pulper-Lite (No-Shim)** | [ghcr.io/alexasaservice/pulper-lite](https://ghcr.io/alexasaservice/pulper-lite) | `latest-no-shim` |

---

## 🎭 Image Flavors

Pulper is offered in two main flavors: **Pulper** (Full) and **Pulper-Lite**.

- **Pulper**: Includes the full suite of conversion tools (LibreOffice, FFmpeg).
- **Pulper-Lite**: A lightweight image focused on modern document formats. It lacks legacy transpilers; if a legacy file is detected, the classifier will log a warning and pass the original file to MarkItDown, which will likely result in a conversion error.

---

## 🔐 Rootless & Permissions

Pulper is designed for rootless execution, but the configuration depends on your orchestration environment.

### The Shim (Recommended for Local Dev)
Images tagged `latest` include a lightweight Bash shim.
- **Mechanism**: The container starts as `root` to map the internal `pulper` user to the UID/GID that owns your mounted volumes, then drops privileges.
- **Benefit**: This ensures that files written to your host `/output` folder are owned by the same user who owns the host directory, avoiding permission conflicts without manual configuration.

### No-Shim (`latest-no-shim`)
Images tagged `latest-no-shim` lack the entrypoint wrapper and run as a non-privileged user named `pulper` by default.
- **Mechanism**: Defaults to UID/GID `9999`. 
- **Usage**: In Docker, you should use the `--user` flag to map the execution to the UID/GID that owns your input/output directories. (Other orchestrators like Kubernetes handle this via security contexts).
- **Complexity with Full Version**: While **Pulper-Lite** is easy to run in `no-shim` mode, the **Full** version requires significant effort. LibreOffice requires a writable `$HOME` directory to initialize its user profile. Since the default home directory in the image is owned by UID `9999`, overriding the user via `--user` will break LibreOffice's ability to write there. You must manually provide a writable path (e.g., `-e HOME=/tmp`) for the conversion tools to function. 

*Note: We offer the no-shim variant for the Full image, but we make no guarantees regarding the compatibility of legacy conversion tools in highly restrictive environments.*

---

## 🛠️ Usage Examples

### Pulper (Full) with Shim
```bash
docker run --rm \
  -v "$PWD/input:/input:ro" \
  -v "$PWD/output:/output" \
  ghcr.io/alexasaservice/pulper:latest \
  /input/report.doc -o /output/report.md
```

### Pulper-Lite with No-Shim
```bash
docker run --rm \
  -v "$PWD/input:/input:ro" \
  -v "$PWD/output:/output" \
  --user $(id -u):$(id -g) \
  ghcr.io/alexasaservice/pulper-lite:latest-no-shim \
  /input/data.docx -o /output/data.md
```

---

## 🏗️ Building From Source

### Using Docker Compose
```bash
# Build the full version
STAGE=full-shim docker compose build

# Build the lite version
STAGE=minimal-shim docker compose build
```

### Testing
- **Unit Tests**: `go test ./cmd/classifier/...` (requires Go on host).
- **Smoke Tests**: `./scripts/smoke.sh [target]` (verifies the container pipeline).

---

## ⚖️ License
MIT. See `LICENSE` for details.

Permission is granted to fork, modify, and redistribute this code. We request that you provide credit and link back to this project in your redistribution.

---
**Pulper** is a project by [Alex As A Service](https://alexasaservice.com). 
*Bridging the gap between messy data and clean AI ingestion.*
