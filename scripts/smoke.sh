#!/usr/bin/env bash
# smoke.sh — Basic smoke test for the Pulper container
#
# Usage:
#   ./scripts/smoke.sh [IMAGE_TAG]
#
# Defaults to pulper:minimal if no tag is given.
# Expects a sample file at tests/fixtures/sample.pdf (or similar).
#
# Exit codes:
#   0 — conversion produced non-empty output
#   1 — conversion failed or produced empty output

set -euo pipefail

IMAGE="${1:-pulper:dev}"
FIXTURES_DIR="$(cd "$(dirname "$0")/../tests/fixtures" && pwd)"
OUTPUT_DIR="$(mktemp -d)"
trap 'rm -rf "$OUTPUT_DIR"' EXIT

echo "==> Smoke test: $IMAGE"
echo "    Fixtures : $FIXTURES_DIR"
echo "    Output   : $OUTPUT_DIR"

# Use the HTML fixture since we can't easily generate PDFs in the repo
SAMPLE_NAME="sample.html"
SAMPLE="$FIXTURES_DIR/$SAMPLE_NAME"
RESULT_NAME="sample.md"

if [[ ! -f "$SAMPLE" ]]; then
  echo "ERROR: sample fixture not found at $SAMPLE" >&2
  exit 1
fi

docker run --rm \
  -v "$FIXTURES_DIR:/input:ro" \
  -v "$OUTPUT_DIR:/output" \
  "$IMAGE" \
  "/input/$SAMPLE_NAME" -o "/output/$RESULT_NAME"

RESULT="$OUTPUT_DIR/$RESULT_NAME"

if [[ ! -s "$RESULT" ]]; then
  echo "FAIL: output file is missing or empty" >&2
  exit 1
fi

echo "--- Output Preview ---"
head -n 20 "$RESULT"
echo "----------------------"

echo "PASS: output written to $RESULT ($(wc -c < "$RESULT") bytes)"
