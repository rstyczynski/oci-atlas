#!/usr/bin/env bash
# Mirrors node_client/examples/client_regions.ts
# Usage: bash examples/regions.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../gdir_regions_v1.sh"

# --- metadata ----------------------------------------------------------------
echo "=== Data last updated ==="
_ts=$(gdir_v1_regions_get_last_updated_timestamp)
echo "${_ts:-(no timestamp — upload via tf_manager to add one)}"

echo ""
# --- map-level ---------------------------------------------------------------
echo "=== All regions ==="
gdir_v1_regions_get_regions

echo ""
echo "=== Region keys ==="
gdir_v1_regions_get_region_keys

echo ""
echo "=== Realms ==="
gdir_v1_regions_get_realms

# --- per-realm breakdown -----------------------------------------------------
while IFS= read -r realm; do
  echo ""
  echo "=== Realm: $realm — region keys ==="
  gdir_v1_regions_get_realm_region_keys "$realm"

  echo ""
  echo "=== Realm: $realm — regions ==="
  gdir_v1_regions_get_realm_regions "$realm"
done < <(gdir_v1_regions_get_realms)

# --- per-region field summary ------------------------------------------------
echo ""
echo "=== Per-region field summary ==="
while IFS= read -r key; do
  export REGION_KEY="$key"

  short_key=$(gdir_v1_regions_get_region_short_key)
  realm=$(gdir_v1_regions_get_region_realm)
  cidr_public=$(gdir_v1_regions_get_region_cidr_public   | jq -r '[.[].cidr] | join(", ")')
  cidr_internal=$(gdir_v1_regions_get_region_cidr_internal | jq -r '[.[].cidr] | join(", ")')
  proxy_ip=$(gdir_v1_regions_get_region_proxy_ip)
  proxy_port=$(gdir_v1_regions_get_region_proxy_port)
  noproxy=$(gdir_v1_regions_get_region_proxy_noproxy_string)
  noproxy_str=$(gdir_v1_regions_get_region_proxy_noproxy_string)
  vault_ocid=$(gdir_v1_regions_get_region_vault_ocid)
  runner_labels=$(gdir_v1_regions_get_region | jq -r '.toolchain.github.runner.labels | join(", ")')
  runner_image=$(gdir_v1_regions_get_region_github_runner_image)
  prom_cidr=$(gdir_v1_regions_get_region_prom_scraping_cidr)
  loki_fqdn=$(gdir_v1_regions_get_region_loki_fqdn)

  echo ""
  echo "[$key]"
  echo "  short key        : $short_key"
  echo "  realm            : $realm"
  echo "  CIDR public      : $cidr_public"
  echo "  CIDR internal    : $cidr_internal"
  echo "  proxy            : $proxy_ip:$proxy_port"
  echo "  noproxy          : $noproxy"
  echo "  NO_PROXY string  : $noproxy_str"
  echo "  vault            : $vault_ocid"
  echo "  runner labels    : $runner_labels"
  echo "  runner image     : $runner_image"
  echo "  prom scrape CIDR : $prom_cidr"
  echo "  loki fqdn        : $loki_fqdn"
done < <(gdir_v1_regions_get_region_keys)
