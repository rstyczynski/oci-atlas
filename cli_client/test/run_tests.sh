#!/usr/bin/env bash
# CLI unit tests — no OCI connectivity required.
# _gdir_fetch is overridden to read local JSON test data.
#
# Usage: bash cli_client/test/run_tests.sh
#        TEST_DATA_DIR=/path/to/tf_manager bash cli_client/test/run_tests.sh

set -euo pipefail

TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLI_DIR="$(cd "$TEST_DIR/.." && pwd)"
PROJECT_ROOT="$(cd "$TEST_DIR/../.." && pwd)"
TEST_DATA_DIR="${TEST_DATA_DIR:-$PROJECT_ROOT/tf_manager}"

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

pass=0; fail=0

_test() {
  local name="$1"; shift
  local output exit_code=0
  output=$("$@" 2>&1) || exit_code=$?
  if [[ $exit_code -eq 0 && -n "$output" ]]; then
    echo "  PASS  $name"
    (( pass += 1 ))
  else
    echo "  FAIL  $name"
    [[ -n "$output" ]] && echo "        → $output"
    (( fail += 1 ))
  fi
}

# Like _test but allows empty output (for optional fields like last_updated_timestamp)
_test_optional() {
  local name="$1"; shift
  local exit_code=0
  "$@" > /dev/null 2>&1 || exit_code=$?
  if [[ $exit_code -eq 0 ]]; then
    echo "  PASS  $name (optional)"
    (( pass += 1 ))
  else
    echo "  FAIL  $name"
    (( fail += 1 ))
  fi
}

# ---------------------------------------------------------------------------
# Regions tests
# ---------------------------------------------------------------------------

echo "=== regions/v1 ==="

# Source DAL — gdir.sh's _gdir_fetch is defined here, we override it below
export GDIR_BUCKET="test_bucket"
# shellcheck source=../gdir_regions_v1.sh
source "$CLI_DIR/gdir_regions_v1.sh"

# Override _gdir_fetch to load local JSON (no OCI call)
_gdir_fetch() {
  [[ -n "$_GDIR_CACHE" ]] && return
  _GDIR_CACHE=$(cat "$TEST_DATA_DIR/regions_v1.json")
}

export REGION_KEY="tst-region-1"

_test_optional "get_last_updated_timestamp"            gdir_v1_regions_get_last_updated_timestamp
_test          "get_regions"                           gdir_v1_regions_get_regions
_test          "get_region_keys"                       gdir_v1_regions_get_region_keys
_test          "get_region"                            gdir_v1_regions_get_region
_test          "get_region_short_key"                  gdir_v1_regions_get_region_short_key
_test          "get_region_realm"                      gdir_v1_regions_get_region_realm
_test          "get_realms"                            gdir_v1_regions_get_realms
_test          "get_realm_regions"                     gdir_v1_regions_get_realm_regions
_test          "get_realm_region_keys"                 gdir_v1_regions_get_realm_region_keys
_test          "get_realm_other_regions"               gdir_v1_regions_get_realm_other_regions
_test          "get_realm_other_region_keys"           gdir_v1_regions_get_realm_other_region_keys
_test          "get_region_cidr_public"                gdir_v1_regions_get_region_cidr_public
_test          "get_region_cidr_internal"              gdir_v1_regions_get_region_cidr_internal
_test          "get_region_cidr_by_tag public"          gdir_v1_regions_get_region_cidr_by_tag public
_test          "get_region_proxy"                      gdir_v1_regions_get_region_proxy
_test          "get_region_proxy_url"                  gdir_v1_regions_get_region_proxy_url
_test          "get_region_proxy_ip"                   gdir_v1_regions_get_region_proxy_ip
_test          "get_region_proxy_port"                 gdir_v1_regions_get_region_proxy_port
_test          "get_region_proxy_noproxy"              gdir_v1_regions_get_region_proxy_noproxy
_test          "get_region_proxy_noproxy_string"       gdir_v1_regions_get_region_proxy_noproxy_string
_test          "get_region_vault"                      gdir_v1_regions_get_region_vault
_test          "get_region_vault_ocid"                 gdir_v1_regions_get_region_vault_ocid
_test          "get_region_vault_crypto_endpoint"      gdir_v1_regions_get_region_vault_crypto_endpoint
_test          "get_region_vault_management_endpoint"  gdir_v1_regions_get_region_vault_management_endpoint
_test          "get_region_github_runner"              gdir_v1_regions_get_region_github_runner
_test          "get_region_github_runner_labels"       gdir_v1_regions_get_region_github_runner_labels
_test          "get_region_github_runner_image"        gdir_v1_regions_get_region_github_runner_image
_test          "get_region_observability"              gdir_v1_regions_get_region_observability
_test          "get_region_prom_scraping_cidr"         gdir_v1_regions_get_region_prom_scraping_cidr
_test          "get_region_loki_dest_cidr"             gdir_v1_regions_get_region_loki_dest_cidr
_test          "get_region_loki_fqdn"                  gdir_v1_regions_get_region_loki_fqdn

# ---------------------------------------------------------------------------
# Realms tests
# ---------------------------------------------------------------------------

echo ""
echo "=== realms/v1 ==="

# Reset cache — new DAL, different data file
_GDIR_CACHE=""
_GDIR_CACHED_REGION_KEY=""
_GDIR_CACHED_REALM=""
_GDIR_CACHED_REALM_FOR=""

# shellcheck source=../gdir_realms_v1.sh
source "$CLI_DIR/gdir_realms_v1.sh"

_gdir_fetch() {
  [[ -n "$_GDIR_CACHE" ]] && return
  _GDIR_CACHE=$(cat "$TEST_DATA_DIR/realms_v1.json")
}

export REALM_KEY="oc1"

_test_optional "get_last_updated_timestamp"  gdir_v1_realms_get_last_updated_timestamp
_test          "get_realms"                  gdir_v1_realms_get_realms
_test          "get_realm_keys"              gdir_v1_realms_get_realm_keys
_test          "get_realm"                   gdir_v1_realms_get_realm
_test          "get_realm_type"              gdir_v1_realms_get_realm_type
_test          "get_realm_name"              gdir_v1_realms_get_realm_name
_test          "get_realm_description"       gdir_v1_realms_get_realm_description
_test          "get_realm_geo_region"        gdir_v1_realms_get_realm_geo_region
_test          "get_realm_api_domain"        gdir_v1_realms_get_realm_api_domain

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------

echo ""
echo "Results: $pass passed, $fail failed"
[[ $fail -eq 0 ]]
