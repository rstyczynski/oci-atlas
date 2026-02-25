#!/usr/bin/env bash
# gdir_regions_v1.sh — v1 regions schema functions for the global directory.
# Tied to regions/v1 field structure: { [regionKey]: { key, realm, network: { public, internal, proxy }, security: { vault }, toolchain: { github }, observability } }
# Source this file to get all gdir_v1_regions_* functions.
#
# ENV vars (all optional):
#   GDIR_REGIONS_OBJECT — object path override (default: regions/v1)

set -euo pipefail

# DAL owns its object path — set before sourcing core so _gdir_fetch uses it.
: "${GDIR_REGIONS_OBJECT:=regions/v1}"
: "${GDIR_OBJECT:=$GDIR_REGIONS_OBJECT}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/gdir.sh"

# ---------- public API v1/regions --------------------------------------------

# ISO 8601 timestamp injected by tf_manager at upload time
gdir_v1_regions_get_last_updated_timestamp() {
  _gdir_fetch
  echo "$_GDIR_CACHE" | jq -r '.last_updated_timestamp // empty'
}

# All regions (pretty JSON), metadata fields excluded
gdir_v1_regions_get_regions() {
  _gdir_fetch
  echo "$_GDIR_CACHE" | jq 'del(.last_updated_timestamp)'
}

# List of all region keys (metadata keys excluded)
gdir_v1_regions_get_region_keys() {
  _gdir_fetch
  echo "$_GDIR_CACHE" | jq -r 'keys[] | select(. != "last_updated_timestamp")'
}

# One region object (REGION_KEY or auto-discovered)
gdir_v1_regions_get_region() {
  _gdir_fetch
  local key; key=$(_gdir_region_key)
  local region
  region=$(echo "$_GDIR_CACHE" | jq --arg k "$key" '.[$k]')
  if [[ "$region" == "null" || -z "$region" ]]; then
    echo "Error: region '$key' not found" >&2; return 1
  fi
  echo "$region" | jq '.'
}

# ---------- short key ---------------------------------------------------------

# Short region code (e.g. ZRH, FRA)
gdir_v1_regions_get_region_short_key() {
  gdir_v1_regions_get_region | jq -r '.key'
}

# ---------- realm -------------------------------------------------------------

# Realm of the active region
gdir_v1_regions_get_region_realm() {
  _gdir_resolve_realm
}

# All distinct realms
gdir_v1_regions_get_realms() {
  _gdir_fetch
  echo "$_GDIR_CACHE" | jq -r 'del(.last_updated_timestamp) | [.[].realm] | unique[]'
}

# All regions in a given realm (or the active region's realm if no arg given)
gdir_v1_regions_get_realm_regions() {
  local realm="${1:-$(_gdir_resolve_realm)}"
  _gdir_fetch
  echo "$_GDIR_CACHE" | jq --arg r "$realm" 'del(.last_updated_timestamp) | with_entries(select(.value.realm == $r))'
}

# Region keys in a given realm (or the active region's realm if no arg given)
gdir_v1_regions_get_realm_region_keys() {
  local realm="${1:-$(_gdir_resolve_realm)}"
  gdir_v1_regions_get_realm_regions "$realm" | jq -r 'keys[]'
}

# All regions in the same realm as the active region, excluding itself
gdir_v1_regions_get_realm_other_regions() {
  _gdir_fetch
  local key; key=$(_gdir_region_key)
  local realm; realm=$(_gdir_resolve_realm)
  echo "$_GDIR_CACHE" | jq \
    --arg r "$realm" \
    --arg k "$key" \
    'del(.last_updated_timestamp) | with_entries(select(.value.realm == $r and .key != $k))'
}

# Keys of other regions in the same realm
gdir_v1_regions_get_realm_other_region_keys() {
  gdir_v1_regions_get_realm_other_regions | jq -r 'keys[]'
}

# ---------- CIDR --------------------------------------------------------------

# Public CIDR entries
gdir_v1_regions_get_region_cidr_public() {
  gdir_v1_regions_get_region | jq '.network.public'
}

# Internal CIDR entries
gdir_v1_regions_get_region_cidr_internal() {
  gdir_v1_regions_get_region | jq '.network.internal'
}

# CIDR entries (public + internal) matching a given tag — usage: gdir_v1_regions_get_region_cidr_by_tag OCI
gdir_v1_regions_get_region_cidr_by_tag() {
  local tag="${1:?usage: gdir_v1_regions_get_region_cidr_by_tag <tag>}"
  gdir_v1_regions_get_region | jq --arg t "$tag" \
    '[.network.public[], .network.internal[]] | map(select(.tags[] == $t))'
}

# ---------- proxy -------------------------------------------------------------

# Proxy object for the region
gdir_v1_regions_get_region_proxy() {
  gdir_v1_regions_get_region | jq '.network.proxy'
}

# Proxy URL
gdir_v1_regions_get_region_proxy_url() {
  gdir_v1_regions_get_region | jq -r '.network.proxy.url'
}

# Proxy IP
gdir_v1_regions_get_region_proxy_ip() {
  gdir_v1_regions_get_region | jq -r '.network.proxy.ip'
}

# Proxy port
gdir_v1_regions_get_region_proxy_port() {
  gdir_v1_regions_get_region | jq -r '.network.proxy.port'
}

# No-proxy list (newline-separated)
gdir_v1_regions_get_region_proxy_noproxy() {
  gdir_v1_regions_get_region | jq -r '.network.proxy.noproxy[]'
}

# No-proxy list as a comma-separated string (ready for NO_PROXY env var)
gdir_v1_regions_get_region_proxy_noproxy_string() {
  gdir_v1_regions_get_region | jq -r '.network.proxy.noproxy | join(",")'
}

# ---------- vault -------------------------------------------------------------

# Full vault object
gdir_v1_regions_get_region_vault() {
  gdir_v1_regions_get_region | jq '.security.vault'
}

# Vault OCID
gdir_v1_regions_get_region_vault_ocid() {
  gdir_v1_regions_get_region | jq -r '.security.vault.ocid'
}

# Vault cryptographic operations endpoint
gdir_v1_regions_get_region_vault_crypto_endpoint() {
  gdir_v1_regions_get_region | jq -r '.security.vault.crypto_endpoint'
}

# Vault management endpoint
gdir_v1_regions_get_region_vault_management_endpoint() {
  gdir_v1_regions_get_region | jq -r '.security.vault.management_endpoint'
}

# ---------- toolchain ---------------------------------------------------------

# Full toolchain object
gdir_v1_regions_get_region_toolchain() {
  gdir_v1_regions_get_region | jq '.toolchain'
}

# Full GitHub object
gdir_v1_regions_get_region_github() {
  gdir_v1_regions_get_region | jq '.toolchain.github'
}

# Full GitHub runner object
gdir_v1_regions_get_region_github_runner() {
  gdir_v1_regions_get_region | jq '.toolchain.github.runner'
}

# GitHub Actions runner labels (newline-separated)
gdir_v1_regions_get_region_github_runner_labels() {
  gdir_v1_regions_get_region | jq -r '.toolchain.github.runner.labels[]'
}

# Compute image OCID used for GitHub runner instances
gdir_v1_regions_get_region_github_runner_image() {
  gdir_v1_regions_get_region | jq -r '.toolchain.github.runner.image'
}

# ---------- observability -----------------------------------------------------

# Full observability object
gdir_v1_regions_get_region_observability() {
  gdir_v1_regions_get_region | jq '.observability'
}

# CIDR allowed to scrape Prometheus
gdir_v1_regions_get_region_prom_scraping_cidr() {
  gdir_v1_regions_get_region | jq -r '.observability.prometheus_scraping_cidr'
}

# CIDR of the Loki destination
gdir_v1_regions_get_region_loki_dest_cidr() {
  gdir_v1_regions_get_region | jq -r '.observability.loki_destination_cidr'
}

# FQDN of the Loki endpoint
gdir_v1_regions_get_region_loki_fqdn() {
  gdir_v1_regions_get_region | jq -r '.observability.loki_fqdn'
}

# When run directly (not sourced), print all regions
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  gdir_v1_regions_get_regions
fi
