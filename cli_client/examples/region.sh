#!/usr/bin/env bash
# Usage: REGION_KEY=eu-zurich-1 bash examples/region.sh
# Shows region (v2) metadata only.
set -euo pipefail

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$BASE_DIR/gdir_regions_v2.sh"

RESOLVED_KEY=$(_gdir_region_key)

echo "=== Region metadata (v2) ==="
gdir_v2_regions_get_region

echo "\n=== Region short key ==="
gdir_v2_regions_get_region_short_key

echo "\n=== Region realm ==="
gdir_v2_regions_get_region_realm

echo "\n=== Public CIDRs ==="
gdir_v2_regions_get_region_cidr_public
