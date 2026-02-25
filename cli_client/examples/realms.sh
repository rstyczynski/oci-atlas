#!/usr/bin/env bash
# Mirrors node_client/examples/client_realms.ts
# Usage: REALM_KEY=oc1 bash examples/realms.sh
#        REALM_KEY is required for single-realm functions.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../gdir_realms_v1.sh"

# --- metadata ----------------------------------------------------------------
echo "=== Data last updated ==="
_ts=$(gdir_v1_realms_get_last_updated_timestamp)
echo "${_ts:-(no timestamp — upload via tf_manager to add one)}"

if [[ -n "${REALM_KEY:-}" ]]; then
  # --- single realm ------------------------------------------------------------
  echo ""
  echo "=== Realm: ${REALM_KEY} ==="
  gdir_v1_realms_get_realm

  echo ""
  echo "=== Field summary: ${REALM_KEY} ==="
  echo "  type        : $(gdir_v1_realms_get_realm_type)"
  echo "  name        : $(gdir_v1_realms_get_realm_name)"
  echo "  description : $(gdir_v1_realms_get_realm_description)"
  echo "  geo-region  : $(gdir_v1_realms_get_realm_geo_region)"
  echo "  api_domain  : $(gdir_v1_realms_get_realm_api_domain)"
else
  # --- all realms --------------------------------------------------------------
  echo ""
  echo "=== All realms ==="
  gdir_v1_realms_get_realms

  echo ""
  echo "=== Realm keys ==="
  gdir_v1_realms_get_realm_keys

  echo ""
  echo "(set REALM_KEY=<key> for single-realm output, e.g. REALM_KEY=oc1)"
fi
