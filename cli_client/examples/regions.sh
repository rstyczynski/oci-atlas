#!/usr/bin/env bash
# Usage: TENANCY_KEY=acme_prod bash examples/regions.sh
# Lists regions and realms from regions_v2 and tenancy coverage.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../gdir_regions_v2.sh"
source "$SCRIPT_DIR/../gdir_tenancies_v1.sh"

echo "=== All regions (v2) ==="
gdir_v2_regions_get_regions

echo "\n=== Region keys ==="
gdir_v2_regions_get_region_keys

echo "\n=== Realms ==="
gdir_v2_regions_get_realms

echo "\n=== Tenancy keys ==="
gdir_v1_tenancies_get_tenancy_keys

echo "\n=== Tenancy region keys ==="
gdir_v1_tenancies_get_tenancy_region_keys
