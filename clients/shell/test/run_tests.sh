#!/usr/bin/env bash
set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$SCRIPT_DIR/.."
export GDIR_CACHE_TTL=0
export GDIR_DATA_DIR="${GDIR_DATA_DIR:-$ROOT/../../manager}"

source "$ROOT/gdir_regions_v2.sh"
source "$ROOT/gdir_tenancies_v1.sh"
source "$ROOT/gdir_realms_v1.sh"

pass() { printf "  PASS  %s\n" "$1"; PASSED=$((PASSED + 1)); }
fail() { printf "  FAIL  %s\n" "$1"; FAILED=$((FAILED + 1)); FAILURES=1; }
PASSED=0
FAILED=0
FAILURES=0

# regions/v2
echo "=== regions/v2 ==="
export REGION_KEY="tst-region-1"
[[ "$(gdir_v2_regions_get_schema_version)" == "1.0.0" ]] && pass "get_schema_version" || fail "get_schema_version"
[[ "$(gdir_v2_regions_get_region_short_key)" == "T01" ]] && pass "get_region_short_key" || fail "get_region_short_key"
[[ "$(gdir_v2_regions_get_region_realm)" == "tst01" ]] && pass "get_region_realm" || fail "get_region_realm"
[[ $(gdir_v2_regions_get_region_keys | wc -l) -gt 0 ]] && pass "get_region_keys" || fail "get_region_keys"
[[ $(gdir_v2_regions_get_realms | wc -l) -gt 0 ]] && pass "get_realms" || fail "get_realms"
[[ $(gdir_v2_regions_get_region_cidr_public | wc -l) -gt 0 ]] && pass "get_region_cidr_public" || fail "get_region_cidr_public"
[[ $(gdir_v2_regions_get_region_cidr_by_tag public | wc -l) -gt 0 ]] && pass "get_region_cidr_by_tag public" || fail "get_region_cidr_by_tag public"

# tenancies/v1
echo "\n=== tenancies/v1 ==="
export TENANCY_KEY="acme_prod"
export REGION_KEY="eu-amsterdam-1"
[[ "$(gdir_v1_tenancies_get_schema_version)" == "1.0.0" ]] && pass "get_schema_version" || fail "get_schema_version (tenancies)"
[[ "$(gdir_v1_tenancies_get_tenancy_realm)" == "oc1" ]] && pass "get_tenancy_realm" || fail "get_tenancy_realm"
[[ $(gdir_v1_tenancies_get_tenancy_region_keys | wc -l) -gt 0 ]] && pass "get_tenancy_region_keys" || fail "get_tenancy_region_keys"
[[ $(gdir_v1_tenancies_get_tenancy_region_cidr_private | wc -l) -gt 0 ]] && pass "get_tenancy_region_cidr_private" || fail "get_tenancy_region_cidr_private"
[[ $(gdir_v1_tenancies_get_tenancy_region_proxy | jq '.url') != "null" ]] && pass "get_tenancy_region_proxy" || fail "get_tenancy_region_proxy"
[[ $(gdir_v1_tenancies_get_tenancy_region_github_runner_labels | wc -l) -gt 0 ]] && pass "get_tenancy_region_github_runner_labels" || fail "get_tenancy_region_github_runner_labels"
[[ -n "$(gdir_v1_tenancies_get_tenancy_region_prom_scraping_cidr)" ]] && pass "get_tenancy_region_prom_scraping_cidr" || fail "get_tenancy_region_prom_scraping_cidr"
[[ -n "$(gdir_v1_tenancies_get_tenancy_region_loki_fqdn)" ]] && pass "get_tenancy_region_loki_fqdn" || fail "get_tenancy_region_loki_fqdn"

# realms/v1
echo "\n=== realms/v1 ==="
export REALM_KEY="oc1"
[[ "$(gdir_v1_realms_get_schema_version)" == "1.0.0" ]] && pass "get_schema_version" || fail "get_schema_version (realms)"
[[ $(gdir_v1_realms_get_realm_keys | wc -l) -gt 0 ]] && pass "get_realm_keys" || fail "get_realm_keys"
[[ "$(gdir_v1_realms_get_realm_type)" == "public" ]] && pass "get_realm_type" || fail "get_realm_type"

if [[ $FAILURES -eq 0 ]]; then
  echo ""
  echo "Results: $PASSED passed, $FAILED failed (all passed)"
  exit 0
else
  echo ""
  echo "Results: $PASSED passed, $FAILED failed (failures present)"
  exit 1
fi
