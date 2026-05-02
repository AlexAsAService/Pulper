#!/usr/bin/env bash
# entrypoint.sh — Handles UID/GID mapping and Auto-Transpiling for Pulper
set -euo pipefail

# 1. Handle UID/GID mapping for bind-mounted volumes
if [[ "$(id -u)" == "0" ]]; then
    USER_ID=${USER_ID:-1000}
    GROUP_ID=${GROUP_ID:-1000}

    if ! getent group pulper >/dev/null; then
        groupadd -g "$GROUP_ID" pulper
    fi

    if ! getent passwd pulper >/dev/null; then
        useradd -u "$USER_ID" -g "$GROUP_ID" -s /bin/bash -m pulper
    fi

    # Ensure /output is writable if it exists
    if [[ -d "/output" ]]; then
        chown -R pulper:pulper /output
    fi

    # Hand off to gosu to drop privileges
    exec gosu pulper "$0" "$@"
fi

# 2. Auto-Transpiling Logic (Runs as non-root pulper user)
if [[ "$1" == "markitdown" ]]; then
    shift # Remove 'markitdown' from the argument list
    
    # We need to find the input file in the arguments.
    # Usually it's the first positional argument.
    INPUT_PATH=""
    OTHER_ARGS=()
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            -o|--output|-x|--extension|-m|--mime-type|-c|--charset|-e|--endpoint)
                OTHER_ARGS+=("$1" "$2")
                shift 2
                ;;
            -*)
                OTHER_ARGS+=("$1")
                shift
                ;;
            *)
                if [[ -z "$INPUT_PATH" ]]; then
                    INPUT_PATH="$1"
                else
                    OTHER_ARGS+=("$1")
                fi
                shift
                ;;
        esac
    done

    # If we found an input path, check if it needs transpiling
    if [[ -n "$INPUT_PATH" && -f "$INPUT_PATH" ]]; then
        EXT="${INPUT_PATH##*.}"
        EXT_LC=$(echo "$EXT" | tr '[:upper:]' '[:lower:]')
        
        TEMP_DIR=$(mktemp -d)
        trap 'rm -rf "$TEMP_DIR"' EXIT
        
        CLEAN_PATH="$INPUT_PATH"

        case "$EXT_LC" in
            doc|odt|rtf)
                echo "==> Transpiling legacy document ($EXT_LC) to docx..." >&2
                soffice --headless --convert-to docx --outdir "$TEMP_DIR" "$INPUT_PATH" >/dev/null 2>&1
                CLEAN_PATH=$(find "$TEMP_DIR" -name "*.docx" | head -n 1)
                ;;
            ods)
                echo "==> Transpiling legacy spreadsheet ($EXT_LC) to xlsx..." >&2
                soffice --headless --convert-to xlsx --outdir "$TEMP_DIR" "$INPUT_PATH" >/dev/null 2>&1
                CLEAN_PATH=$(find "$TEMP_DIR" -name "*.xlsx" | head -n 1)
                ;;
            ppt|odp)
                echo "==> Transpiling legacy presentation ($EXT_LC) to pptx..." >&2
                soffice --headless --convert-to pptx --outdir "$TEMP_DIR" "$INPUT_PATH" >/dev/null 2>&1
                CLEAN_PATH=$(find "$TEMP_DIR" -name "*.pptx" | head -n 1)
                ;;
            wav|mp3|m4a|ogg|flac)
                # Check for audio issues (like the 32-bit float problem)
                # For safety, we just normalize to a standard 16-bit mono WAV at 16k
                echo "==> Normalizing audio ($EXT_LC) via FFmpeg..." >&2
                CLEAN_PATH="$TEMP_DIR/normalized.wav"
                ffmpeg -i "$INPUT_PATH" -ac 1 -ar 16000 -acodec pcm_s16le "$CLEAN_PATH" -y >/dev/null 2>&1
                ;;
        esac

        # Execute markitdown with the (potentially) new path
        exec markitdown "$CLEAN_PATH" "${OTHER_ARGS[@]}"
    else
        # No file found or not a file (stdin mode), just run markitdown as-is
        exec markitdown "${OTHER_ARGS[@]}"
    fi
fi

# Fallback for other commands
exec "$@"
