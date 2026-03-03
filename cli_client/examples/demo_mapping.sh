#!/usr/bin/env bash
# demo_mapping.sh — Demo mode: map auto-discovered real tenancy key to a synthetic template tenant.
#
# Purpose:
#   Shows how synthetic demo data from tenancies/v1 can be presented in the context of the
#   currently active OCI connection. The real tenancy key is discovered at runtime (Sprint 5
#   mechanism). The synthetic template tenant's data is returned as-is, with a clear note
#   that this is demo mode only.
#
# IMPORTANT: This is demo mode only. In production, data must be supplied by the data owner.
#
# Usage:
#   GDIR_DEMO_MODE=true bash examples/demo_mapping.sh
#   GDIR_DEMO_MODE=true GDIR_DEMO_TENANT=acme_prod GDIR_DEMO_MAX_REGIONS=2 bash examples/demo_mapping.sh
#   GDIR_DEMO_MODE=true TENANCY_KEY=demo_corp bash examples/demo_mapping.sh
#
# Environment Variables:
#   GDIR_DEMO_MODE          Must be "true" to activate demo mapping. Required.
#   GDIR_DEMO_TENANT        Synthetic template tenant key (default: acme_prod).
#   GDIR_DEMO_MAX_REGIONS   Maximum number of regions to include in output (default: 4).
#   TENANCY_KEY             Optional explicit tenancy key override for real tenancy discovery.

set -euo pipefail

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$BASE_DIR/gdir_tenancies_v1.sh"

# --- Guard: demo mode must be explicitly enabled ---
if [[ "${GDIR_DEMO_MODE:-}" != "true" ]]; then
  echo "ERROR: Set GDIR_DEMO_MODE=true to enable demo mapping. This procedure is for demo/testing only." >&2
  echo "  Example: GDIR_DEMO_MODE=true bash examples/demo_mapping.sh" >&2
  false
fi

GDIR_DEMO_TENANT="${GDIR_DEMO_TENANT:-acme_prod}"
GDIR_DEMO_MAX_REGIONS="${GDIR_DEMO_MAX_REGIONS:-4}"

# --- Validate max_regions is a positive integer ---
if ! [[ "$GDIR_DEMO_MAX_REGIONS" =~ ^[1-9][0-9]*$ ]]; then
  echo "WARNING: GDIR_DEMO_MAX_REGIONS='$GDIR_DEMO_MAX_REGIONS' is invalid; defaulting to 4." >&2
  GDIR_DEMO_MAX_REGIONS=4
fi

echo "=== Demo Mode Mapping ===" >&2
echo "Template tenant : $GDIR_DEMO_TENANT" >&2
echo "Max regions     : $GDIR_DEMO_MAX_REGIONS" >&2

# --- Discover real tenancy key ---
real_tenancy_key="$(_gdir_v1_tenancies_resolved_key)"
echo "Real tenancy key: $real_tenancy_key" >&2

# --- Retrieve all tenants from dataset ---
all_tenants="$(_gdir_v1_tenancies_get_tenancies_json)"

# --- Validate template tenant exists ---
template_exists="$(echo "$all_tenants" | jq -r --arg t "$GDIR_DEMO_TENANT" 'has($t)')"
if [[ "$template_exists" != "true" ]]; then
  echo "ERROR: Demo template tenant '$GDIR_DEMO_TENANT' not found in tenancies/v1 dataset." >&2
  echo "  Available tenants: $(echo "$all_tenants" | jq -r 'keys | join(", ")')" >&2
  false
fi

# --- Get template tenant's region list (limited to GDIR_DEMO_MAX_REGIONS) ---
region_keys="$(echo "$all_tenants" | jq -r --arg t "$GDIR_DEMO_TENANT" '.[$t].regions | keys[]' | head -n "$GDIR_DEMO_MAX_REGIONS")"
region_count="$(echo "$region_keys" | grep -c . || true)"

if [[ "$region_count" -eq 0 ]]; then
  echo "WARNING: No regions found for template tenant '$GDIR_DEMO_TENANT'. Check the dataset." >&2
fi

# --- Build output ---
mapped_regions_json="$(echo "$region_keys" | jq -R . | jq -s .)"

echo "$all_tenants" | jq \
  --arg real_key "$real_tenancy_key" \
  --arg template "$GDIR_DEMO_TENANT" \
  --argjson regions "$mapped_regions_json" \
  '{
    demo_mode: true,
    real_tenancy_key: $real_key,
    template_tenant: $template,
    mapped_regions: $regions,
    template_data: (.[$template] | .regions |= with_entries(select(.key as $k | $regions | index($k) != null))),
    note: "Demo mode: synthetic tenant data mapped to real tenancy key. Not for production use. Supply real data via your data owner."
  }'
