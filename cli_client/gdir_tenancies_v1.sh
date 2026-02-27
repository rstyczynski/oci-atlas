#!/usr/bin/env bash
# gdir_tenancies_v1.sh — v1 tenancies schema functions.
# Structure: { [tenancyKey]: { realm, regions: { [regionKey]: { network, security, toolchain, observability } } }, last_updated_timestamp?, schema_version? }

set -euo pipefail

: "${GDIR_TENANCIES_OBJECT:=tenancies/v1}"
_gdir_tenancies_v1_set_object() { GDIR_OBJECT="$GDIR_TENANCIES_OBJECT"; }
: "${TENANCY_KEY:=${TENANCY_KEY:-}}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/gdir.sh"

# ---------- metadata --------------------------------------------------------

gdir_v1_tenancies_get_schema_version() {
  _gdir_tenancies_v1_set_object
  _gdir_fetch
  echo "$_GDIR_CACHE" | jq -r '.schema_version // empty'
}

gdir_v1_tenancies_get_last_updated_timestamp() {
  _gdir_tenancies_v1_set_object
  _gdir_fetch
  echo "$_GDIR_CACHE" | jq -r '.last_updated_timestamp // empty'
}

# ---------- helpers ---------------------------------------------------------

_gdir_v1_tenancies_get_tenancies_json() {
  _gdir_tenancies_v1_set_object
  _gdir_fetch
  echo "$_GDIR_CACHE" | jq 'del(.last_updated_timestamp, .schema_version)'
}

_gdir_v1_tenancies_resolved_key() {
  if [[ -z "${TENANCY_KEY:-}" ]]; then
    echo "TENANCY_KEY must be set" >&2; exit 1; fi
  echo "$TENANCY_KEY"
}

_gdir_v1_tenancies_region_key() { _gdir_region_key; }

_gdir_v1_tenancies_tenancy_json() {
  local key="$(_gdir_v1_tenancies_resolved_key)"
  _gdir_v1_tenancies_get_tenancies_json | jq --arg k "$key" '.[$k]'
}

_gdir_v1_tenancies_region_json() {
  local rkey="$(_gdir_v1_tenancies_region_key)"
  _gdir_v1_tenancies_tenancy_json | jq --arg r "$rkey" '.regions[$r]'
}

# ---------- catalog ---------------------------------------------------------

gdir_v1_tenancies_get_tenancies() { _gdir_v1_tenancies_get_tenancies_json; }

gdir_v1_tenancies_get_tenancy_keys() {
  _gdir_v1_tenancies_get_tenancies_json | jq -r 'keys[]'
}

gdir_v1_tenancies_get_tenancy() { _gdir_v1_tenancies_tenancy_json; }

gdir_v1_tenancies_get_tenancy_realm() {
  _gdir_v1_tenancies_tenancy_json | jq -r '.realm'
}

gdir_v1_tenancies_get_tenancy_region_keys() {
  _gdir_v1_tenancies_tenancy_json | jq -r '.regions | keys[]'
}

gdir_v1_tenancies_get_tenancy_region() { _gdir_v1_tenancies_region_json; }

# ---------- network ---------------------------------------------------------

gdir_v1_tenancies_get_tenancy_region_network() {
  _gdir_v1_tenancies_region_json | jq '.network'
}

gdir_v1_tenancies_get_tenancy_region_cidr_private() {
  _gdir_v1_tenancies_region_json | jq '.network.private'
}

gdir_v1_tenancies_get_tenancy_region_cidr_private_by_tag() {
  local tag="${1:?tag required}"
  _gdir_v1_tenancies_region_json | jq --arg tag "$tag" '.network.private | map(select(.tags[]? == $tag))'
}

gdir_v1_tenancies_get_tenancy_region_proxy() {
  _gdir_v1_tenancies_region_json | jq '.network.proxy'
}

gdir_v1_tenancies_get_tenancy_region_proxy_url() { gdir_v1_tenancies_get_tenancy_region_proxy | jq -r '.url'; }

gdir_v1_tenancies_get_tenancy_region_proxy_ip() { gdir_v1_tenancies_get_tenancy_region_proxy | jq -r '.ip'; }

gdir_v1_tenancies_get_tenancy_region_proxy_port() { gdir_v1_tenancies_get_tenancy_region_proxy | jq -r '.port'; }

gdir_v1_tenancies_get_tenancy_region_proxy_noproxy() { gdir_v1_tenancies_get_tenancy_region_proxy | jq '.noproxy'; }

gdir_v1_tenancies_get_tenancy_region_proxy_noproxy_string() { gdir_v1_tenancies_get_tenancy_region_proxy | jq -r '.noproxy | join(",")'; }

# ---------- security --------------------------------------------------------

gdir_v1_tenancies_get_tenancy_region_vault() { _gdir_v1_tenancies_region_json | jq '.security.vault'; }

gdir_v1_tenancies_get_tenancy_region_vault_ocid() { gdir_v1_tenancies_get_tenancy_region_vault | jq -r '.ocid'; }

gdir_v1_tenancies_get_tenancy_region_vault_crypto_endpoint() { gdir_v1_tenancies_get_tenancy_region_vault | jq -r '.crypto_endpoint'; }

gdir_v1_tenancies_get_tenancy_region_vault_management_endpoint() { gdir_v1_tenancies_get_tenancy_region_vault | jq -r '.management_endpoint'; }

# ---------- toolchain -------------------------------------------------------

gdir_v1_tenancies_get_tenancy_region_github() { _gdir_v1_tenancies_region_json | jq '.toolchain.github'; }

gdir_v1_tenancies_get_tenancy_region_github_runner() { gdir_v1_tenancies_get_tenancy_region_github | jq '.runner'; }

gdir_v1_tenancies_get_tenancy_region_github_runner_labels() { gdir_v1_tenancies_get_tenancy_region_github_runner | jq '.labels'; }

gdir_v1_tenancies_get_tenancy_region_github_runner_image() { gdir_v1_tenancies_get_tenancy_region_github_runner | jq -r '.image'; }

# ---------- observability ---------------------------------------------------

gdir_v1_tenancies_get_tenancy_region_observability() { _gdir_v1_tenancies_region_json | jq '.observability'; }

gdir_v1_tenancies_get_tenancy_region_prom_scraping_cidr() { gdir_v1_tenancies_get_tenancy_region_observability | jq -r '.prometheus_scraping_cidr'; }

gdir_v1_tenancies_get_tenancy_region_loki_dest_cidr() { gdir_v1_tenancies_get_tenancy_region_observability | jq -r '.loki_destination_cidr'; }

gdir_v1_tenancies_get_tenancy_region_loki_fqdn() { gdir_v1_tenancies_get_tenancy_region_observability | jq -r '.loki_fqdn'; }

# When run directly, print tenancy map
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  gdir_v1_tenancies_get_tenancies
fi
