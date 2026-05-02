# Product Overview — Containerized Document-to-Markdown Conversion Tool

## Summary
A clean, production-minded containerization of Microsoft MarkItDown for converting common document formats into Markdown through a predictable, portable runtime. Designed for developers, AI workflows, and document-processing pipelines that need reliable Markdown extraction without installing Python packages, native dependencies, OCR tooling, office converters, or media-processing utilities directly on the host.

## Purpose
Modern AI and automation workflows often need to turn messy source documents into plain text or Markdown before indexing, summarizing, embedding, or handing content to agents. Installing document conversion tooling directly on a workstation or server can be inconsistent and fragile. This project packages the conversion workflow into a repeatable container interface with sane defaults, clean volume boundaries, and documented usage patterns.

## Core Capabilities
- **Universal Markdown Conversion**: Converts modern formats (`.docx`, `.xlsx`, `.pptx`) and legacy formats (`.doc`, `.xls`, `.ppt`, `.rtf`, `.odt`, `.ods`, `.odp`) into clean Markdown.
- **Auto-Transpilation**: Transparently uses LibreOffice to modernize legacy documents before conversion.
- **Audio Normalization**: Automatically normalizes audio files (PCM, Bitrate) via FFmpeg to ensure compatibility with transcription engines.
- **Portable & Secure**: Automatic UID/GID mapping ensures "It Just Works" on any host without permission headaches, while strictly running as a non-root user.
- **Predictable Interface**: Simple `/input` and `/output` volume mapping.

## Primary Interface
- CLI-first container execution
- Inputs mounted read-only into /input
- Outputs written to /output
- Optional flags passed through to the conversion command

## Example Usage
    docker run --rm \
      -v "$PWD/input:/input:ro" \
      -v "$PWD/output:/output" \
      document-markdown-container \
      /input/report.pdf -o /output/report.md

## Design Principles
- Host Cleanliness — No Python, OCR, office, or media dependencies installed on the host
- Reproducibility — Same container image produces consistent behavior across machines
- Pipeline Friendly — Designed for scripting, CI jobs, local automation, and agent ingestion flows
- Safe File Boundaries — Explicit input/output mounts instead of uncontrolled filesystem access
- Minimal Surprise — Clear defaults, clear errors, and documented examples
- Extensible Core — Starts as a CLI image, with room to grow into API, queue, or batch modes later

## System Architecture
- Container image provides the runtime environment
- MarkItDown performs the document-to-Markdown conversion
- Optional native dependencies support richer file handling
- /input is treated as read-only source material
- /output is treated as the generated artifact directory
- Scripts and examples demonstrate repeatable conversion workflows

## Operational Features
- Non-root container user
- Read-only input mounts
- Explicit output directory
- Version-pinned dependencies
- Smoke tests using representative sample files
- Clear image tags for minimal and full builds
- Optional local Compose setup for repeatable testing

## Target Use Cases
- Preparing documents for LLM prompts
- Building ingestion pipelines for RAG systems
- Converting business documents into Markdown for review or indexing
- Extracting text from mixed-format project folders
- Running document conversion in CI without polluting the runner
- Giving AI agents a clean, repeatable document normalization tool

## Deployment Model
- Local CLI container for one-off conversions
- Scriptable container command for batch jobs
- CI/CD-friendly image for automated document processing
- Future optional service mode for HTTP-based conversion

## Non-Goals
- Not a full document editor
- Not a perfect layout-preserving converter
- Not a visual reasoning system
- Not a replacement for human review of OCR-heavy documents
- Not initially a hosted SaaS or distributed queue system

## Value Proposition
This project turns document-to-Markdown conversion into a clean, portable, container-native utility. It removes dependency chaos from the host machine, creates a repeatable workflow for AI and automation pipelines, and provides a professional foundation that can later expand into richer OCR, API, batch, or agent-oriented document ingestion features.