#!/usr/bin/env bash
# smoke.sh — Basic smoke test for the Pulper container
#
# Usage:
#   ./scripts/smoke.sh [IMAGE_TAG]
#
# Defaults to pulper:dev if no tag is given.

set -euo pipefail

REGISTRY="${REGISTRY:-docker.io}"
OWNER="${OWNER:-local}"
PRODUCT="${PRODUCT:-pulper}"
VARIANT="${VARIANT:-}"
TAG="${TAG:-latest}"
IMAGE="${IMAGE:-${REGISTRY}/${OWNER}/${PRODUCT}:${TAG}${VARIANT}}"
DOCKER_OPTS="${DOCKER_OPTS:-}"

# Convert DOCKER_OPTS string to an array for safe unrolling
DOCKER_OPTS_ARRAY=()
if [[ -n "$DOCKER_OPTS" ]]; then
    read -r -a DOCKER_OPTS_ARRAY <<< "$DOCKER_OPTS"
fi

FIXTURES_STAGE="${FIXTURES_STAGE:-full}"
FIXTURES_DIR="$(cd "$(dirname "$0")/../tests/fixtures/${FIXTURES_STAGE}" && pwd)"
OUTPUT_DIR="${OUTPUT_DIR:-}"
if [[ -z "$OUTPUT_DIR" ]]; then
    OUTPUT_DIR="$(mktemp -d)"
    trap 'rm -rf "$OUTPUT_DIR"' EXIT
fi

# Ensure output directory exists before Docker mounts it
mkdir -p "$OUTPUT_DIR"

echo "==> Starting Smoke Tests"
echo "    Product  : $PRODUCT"
echo "    Variant  : $VARIANT"
echo "    Tag      : $TAG"
echo "    Image    : $IMAGE"
echo "    Fixtures Stage : $FIXTURES_STAGE"
echo "    Fixtures Dir : $FIXTURES_DIR"
echo "    Output Dir   : $OUTPUT_DIR"
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
      -v "$FIXTURES_DIR:/input:ro" \
      -v "$OUTPUT_DIR:/output" \
      "${DOCKER_OPTS_ARRAY[@]}" \
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
find "$FIXTURES_DIR" -maxdepth 1 -type f ! -name ".*" ! -name "README.md" -print0 | while IFS= read -r -d '' fixture; do
    if ! test_file "$fixture"; then
        echo "--------------------------------------------------"
        echo "SMOKE TEST FAILED"
        exit 1
    fi
done

echo "--------------------------------------------------"
echo "ALL SMOKE TESTS PASSED"
