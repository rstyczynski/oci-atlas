#!/usr/bin/env bash
# Usage: REGION_KEY=eu-zurich-1 TENANCY_KEY=acme_prod bash examples/region.sh
# Shows region (v2) metadata and tenancy-specific details for a region.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../gdir_regions_v2.sh"
source "$SCRIPT_DIR/../gdir_tenancies_v1.sh"

RESOLVED_KEY=$(_gdir_region_key)

echo "=== Region metadata (v2) ==="
gdir_v2_regions_get_region

echo "\n=== Region short key ==="
gdir_v2_regions_get_region_short_key

echo "\n=== Region realm ==="
gdir_v2_regions_get_region_realm

echo "\n=== Public CIDRs ==="
gdir_v2_regions_get_region_cidr_public

echo "\n=== Tenancy realm ==="
gdir_v1_tenancies_get_tenancy_realm

echo "\n=== Tenancy region network ==="
gdir_v1_tenancies_get_tenancy_region_network

echo "\n=== Proxy URL ==="
gdir_v1_tenancies_get_tenancy_region_proxy_url

echo "\n=== GitHub runner labels ==="
gdir_v1_tenancies_get_tenancy_region_github_runner_labels

echo "\n=== Prometheus scraping CIDR ==="
gdir_v1_tenancies_get_tenancy_region_prom_scraping_cidr
