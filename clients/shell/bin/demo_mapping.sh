#!/usr/bin/env bash
# demo_mapping.sh — Tenancy query with demo fallback.
#
# Auto-discovers the real tenancy key and active region. If the tenancy exists in the
# catalog, serves real data (pass-through). If not found, GDIR_DEMO_MODE=true activates
# a fallback using synthetic template data — transparently, in the same format as
# examples/tenancy.sh.
#
# IMPORTANT: Demo fallback is for demo/test environments only. In production, all tenancy
# data must be supplied by the data owner via the catalog.
#
# Usage (live OCI connection — tenancy key, region, and realm auto-discovered):
#   GDIR_DEMO_MODE=true bash bin/demo_mapping.sh
#
# Usage (offline — explicit overrides required):
#   GDIR_DATA_DIR=../../manager GDIR_DEMO_MODE=true TENANCY_KEY=my_corp REGION_KEY=eu-frankfurt-1 \
#     bash bin/demo_mapping.sh
#
# Environment Variables:
#   GDIR_DEMO_MODE    Must be "true" to enable demo fallback. Required.
#   GDIR_DEMO_TENANT  Synthetic template tenant key used as fallback (default: acme_prod).
#   TENANCY_KEY       Optional: override real tenancy key discovery.
#   REGION_KEY        Optional: override region key discovery (required in offline mode).

set -euo pipefail

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$BASE_DIR/gdir_tenancies_v1.sh"

# --- Guard: demo fallback must be explicitly enabled ---
if [[ "${GDIR_DEMO_MODE:-}" != "true" ]]; then
  echo "ERROR: Set GDIR_DEMO_MODE=true to enable demo fallback mode." >&2
  echo "  Example: GDIR_DEMO_MODE=true bash bin/demo_mapping.sh" >&2
  false
fi

GDIR_DEMO_TENANT="${GDIR_DEMO_TENANT:-acme_prod}"

# --- Discover real tenancy key ---
# Use TENANCY_KEY override if set; otherwise call OCI CLI directly.
# NOTE: _gdir_v1_tenancies_resolved_key() validates against the catalog and would
# fail when the tenancy is not yet onboarded — so we bypass it here.
if [[ -n "${TENANCY_KEY:-}" ]]; then
  real_tenancy_key="$TENANCY_KEY"
else
  _ocid="$(oci os ns get-metadata --query 'data."default-s3-compartment-id"' --raw-output)"
  real_tenancy_key="$(oci iam tenancy get --tenancy-id "$_ocid" --query 'data.name' --raw-output)"
fi

# --- Discover real region key ---
real_region_key="$(_gdir_region_key)"

echo "=== Demo Mode ===" >&2
echo "Real tenancy key : $real_tenancy_key" >&2
echo "Real region key  : $real_region_key" >&2

# --- Check whether real tenancy has data in the catalog ---
_all_tenants="$(_gdir_v1_tenancies_get_tenancies_json)"
_tenancy_in_catalog="$(echo "$_all_tenants" | jq -r --arg k "$real_tenancy_key" 'has($k)')"

if [[ "$_tenancy_in_catalog" == "true" ]]; then
  echo "Catalog: real data found — serving live data." >&2
  export TENANCY_KEY="$real_tenancy_key"
  export REGION_KEY="$real_region_key"
else
  echo "Catalog: no data for '$real_tenancy_key' — serving demo template (template: $GDIR_DEMO_TENANT)." >&2
  export TENANCY_KEY="$GDIR_DEMO_TENANT"
  REGION_KEY="$(gdir_v1_tenancies_get_tenancy_region_keys | head -1)"
  export REGION_KEY
fi

echo "" >&2

# --- Serve tenancy data (same output as examples/tenancy.sh) ---
echo "=== Tenancy keys ==="
gdir_v1_tenancies_get_tenancy_keys

echo "\n=== Tenancy realm ==="
gdir_v1_tenancies_get_tenancy_realm

echo "\n=== Region keys for tenancy ==="
gdir_v1_tenancies_get_tenancy_region_keys

echo "\n=== Network (private CIDRs) ==="
gdir_v1_tenancies_get_tenancy_region_cidr_private

echo "\n=== Proxy ==="
gdir_v1_tenancies_get_tenancy_region_proxy

echo "\n=== Vault ==="
gdir_v1_tenancies_get_tenancy_region_vault

echo "\n=== GitHub runner labels ==="
gdir_v1_tenancies_get_tenancy_region_github_runner_labels

echo "\n=== Observability (Prometheus scraping CIDR) ==="
gdir_v1_tenancies_get_tenancy_region_prom_scraping_cidr
