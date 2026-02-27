#!/usr/bin/env bash
# Usage: bash examples/regions.sh
# Lists regions and realms from regions_v2.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../gdir_regions_v2.sh"

echo "=== All regions (v2) ==="
gdir_v2_regions_get_regions

echo "\n=== Region keys ==="
gdir_v2_regions_get_region_keys

echo "\n=== Realms ==="
gdir_v2_regions_get_realms
