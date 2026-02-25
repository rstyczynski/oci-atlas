#!/usr/bin/env bash
# Validate Node.js client on Linux using Podman.
# Runs Jest tests inside a Linux container — no OCI credentials needed.
#
# Usage:
#   bash node_client/test/validate_linux.sh
#   IMAGE=node:18-slim bash node_client/test/validate_linux.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
IMAGE="${IMAGE:-node:20-slim}"

echo "=== Linux Node.js validation via Podman ==="
echo "  Image   : $IMAGE"
echo "  Project : $PROJECT_ROOT"
echo ""

podman run --rm \
  --volume "$PROJECT_ROOT:/workspace:ro" \
  "$IMAGE" \
  bash -c "
    cp -r /workspace/node_client /tmp/node_client
    cp -r /workspace/tf_manager  /tmp/tf_manager
    cd /tmp/node_client
    npm install --silent
    TEST_DATA_DIR=/tmp/tf_manager npm test
  "
