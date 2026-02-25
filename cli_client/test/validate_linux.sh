#!/usr/bin/env bash
# Validate CLI scripts on Linux using Podman.
# Runs run_tests.sh inside a Linux container — no OCI credentials needed.
#
# Usage:
#   bash cli_client/test/validate_linux.sh                      # Ubuntu 24.04 (default)
#   IMAGE=oraclelinux:8 bash cli_client/test/validate_linux.sh  # Oracle Linux 8

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
IMAGE="${IMAGE:-ubuntu:24.04}"

echo "=== Linux CLI validation via Podman ==="
echo "  Image   : $IMAGE"
echo "  Project : $PROJECT_ROOT"
echo ""

# Install jq for the target distro
case "$IMAGE" in
  ubuntu:*|debian:*)
    INSTALL_JQ="apt-get update -qq && apt-get install -y -qq jq"
    ;;
  oraclelinux:*|almalinux:*|rockylinux:*)
    INSTALL_JQ="dnf install -y -q jq"
    ;;
  alpine:*)
    INSTALL_JQ="apk add --no-cache jq"
    ;;
  *)
    INSTALL_JQ="echo 'WARNING: unknown distro — assuming jq is pre-installed'"
    ;;
esac

podman run --rm \
  --volume "$PROJECT_ROOT:/workspace:ro" \
  --env "TEST_DATA_DIR=/workspace/tf_manager" \
  --workdir "/workspace" \
  "$IMAGE" \
  bash -c "$INSTALL_JQ && bash cli_client/test/run_tests.sh"
