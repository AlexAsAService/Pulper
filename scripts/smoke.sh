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

IMAGE="${1:-pulper:minimal}"
FIXTURES_DIR="$(cd "$(dirname "$0")/../tests/fixtures" && pwd)"
OUTPUT_DIR="$(mktemp -d)"
trap 'rm -rf "$OUTPUT_DIR"' EXIT

echo "==> Smoke test: $IMAGE"
echo "    Fixtures : $FIXTURES_DIR"
echo "    Output   : $OUTPUT_DIR"

# TODO: replace with actual sample file once fixtures are committed
SAMPLE="$FIXTURES_DIR/sample.pdf"

if [[ ! -f "$SAMPLE" ]]; then
  echo "ERROR: sample fixture not found at $SAMPLE" >&2
  echo "       Add a representative file to tests/fixtures/ to enable smoke tests."
  exit 1
fi

docker run --rm \
  -v "$FIXTURES_DIR:/input:ro" \
  -v "$OUTPUT_DIR:/output" \
  "$IMAGE" \
  /input/sample.pdf -o /output/sample.md

RESULT="$OUTPUT_DIR/sample.md"

if [[ ! -s "$RESULT" ]]; then
  echo "FAIL: output file is missing or empty" >&2
  exit 1
fi

echo "PASS: output written to $RESULT ($(wc -c < "$RESULT") bytes)"
