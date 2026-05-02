#!/usr/bin/env bash
# smoke.sh — Basic smoke test for the Pulper container
#
# Usage:
#   ./scripts/smoke.sh [IMAGE_TAG]
#
# Defaults to pulper:dev if no tag is given.

set -euo pipefail

IMAGE="${1:-pulper:dev}"
FIXTURES_DIR="$(cd "$(dirname "$0")/../tests/fixtures" && pwd)"
TARGET_DIR="${TARGET_DIR:-}"
OUTPUT_DIR="${OUTPUT_DIR:-}"
if [[ -z "$OUTPUT_DIR" ]]; then
    OUTPUT_DIR="$(mktemp -d)"
    trap 'rm -rf "$OUTPUT_DIR"' EXIT
fi

echo "==> Starting Smoke Tests"
echo "    Image    : $IMAGE"
echo "    Fixtures : $FIXTURES_DIR"
echo "    Output   : $OUTPUT_DIR"
echo "--------------------------------------------------"

# Function to test a single file
test_file() {
    local input_file="$1"
    local filename=$(basename "$input_file")
    local result_name="${filename%.*}.md"
    local result_path="$OUTPUT_DIR/$result_name"

    echo "Testing: $filename..."

    # Run the conversion
    docker run --rm \
      -v "${FIXTURES_DIR}${TARGET_DIR}:/input:ro" \
      -v "$OUTPUT_DIR:/output" \
      "$IMAGE" \
      "/input/$filename" -o "/output/$result_name"

    # Validation
    if [[ ! -s "$result_path" ]]; then
        echo "  FAILED: Output file is missing or empty" >&2
        return 1
    fi

    echo "  PASSED: $(wc -c < "$result_path") bytes written to $result_name"
    return 0
}

# Run tests for all files in the fixtures directory (excluding hidden files and README)
find "${FIXTURES_DIR}${TARGET_DIR}" -maxdepth 1 -type f ! -name ".*" ! -name "README.md" | while read -r fixture; do
    if ! test_file "$fixture"; then
        echo "--------------------------------------------------"
        echo "SMOKE TEST FAILED"
        exit 1
    fi
done

echo "--------------------------------------------------"
echo "ALL SMOKE TESTS PASSED"
