#!/usr/bin/env bash
# gdir_regions_v2.sh — v2 regions schema functions for the global directory.
# Structure: { [regionKey]: { key, realm, network: { public } }, last_updated_timestamp?, schema_version? }
# Source this file to get all gdir_v2_regions_* functions.

set -euo pipefail

: "${GDIR_REGIONS_OBJECT:=regions/v2}"
_gdir_regions_v2_set_object() { GDIR_OBJECT="$GDIR_REGIONS_OBJECT"; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/gdir.sh"

# ---------- metadata --------------------------------------------------------

gdir_v2_regions_get_schema_version() {
  _gdir_regions_v2_set_object
  _gdir_fetch
  echo "$_GDIR_CACHE" | jq -r '.schema_version // empty'
}

gdir_v2_regions_get_last_updated_timestamp() {
  _gdir_regions_v2_set_object
  _gdir_fetch
  echo "$_GDIR_CACHE" | jq -r '.last_updated_timestamp // empty'
}

# ---------- helpers ---------------------------------------------------------

_gdir_v2_regions_get_regions_json() {
  _gdir_regions_v2_set_object
  _gdir_fetch
  echo "$_GDIR_CACHE" | jq 'del(.last_updated_timestamp, .schema_version)'
}

_gdir_v2_regions_resolved_key() {
  _gdir_region_key
}

_gdir_v2_regions_region_json() {
  local key="$(_gdir_v2_regions_resolved_key)"
  _gdir_v2_regions_get_regions_json | jq --arg k "$key" '.[$k]'
}

# ---------- map-level -------------------------------------------------------

gdir_v2_regions_get_regions() { _gdir_v2_regions_get_regions_json; }

gdir_v2_regions_get_region_keys() {
  _gdir_v2_regions_get_regions_json | jq -r 'keys[]'
}

gdir_v2_regions_get_realms() {
  _gdir_v2_regions_get_regions_json | jq -r 'to_entries | map(.value.realm) | unique | .[]'
}

# ---------- single region ---------------------------------------------------

gdir_v2_regions_get_region() { _gdir_v2_regions_region_json; }

gdir_v2_regions_get_region_short_key() {
  _gdir_v2_regions_region_json | jq -r '.key'
}

gdir_v2_regions_get_region_realm() {
  _gdir_v2_regions_region_json | jq -r '.realm'
}

# ---------- realm grouping --------------------------------------------------

gdir_v2_regions_get_realm_regions() {
  local realm; realm=$(gdir_v2_regions_get_region_realm)
  _gdir_v2_regions_get_regions_json | jq --arg r "$realm" 'to_entries | map(select(.value.realm==$r)) | from_entries'
}

gdir_v2_regions_get_realm_region_keys() {
  gdir_v2_regions_get_realm_regions | jq -r 'keys[]'
}

gdir_v2_regions_get_realm_other_regions() {
  local self; self=$(_gdir_v2_regions_resolved_key)
  gdir_v2_regions_get_realm_regions | jq --arg self "$self" 'del(.[$self])'
}

gdir_v2_regions_get_realm_other_region_keys() {
  gdir_v2_regions_get_realm_other_regions | jq -r 'keys[]?'
}

# ---------- network ---------------------------------------------------------

gdir_v2_regions_get_region_cidr_public() {
  _gdir_v2_regions_region_json | jq '.network.public // []'
}

gdir_v2_regions_get_region_cidr_by_tag() {
  local tag="${1:?tag required}"
  _gdir_v2_regions_region_json | jq --arg tag "$tag" '(.network.public // []) | map(select(.tags[]? == $tag))'
}

# When run directly, print regions map
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  gdir_v2_regions_get_regions
fi
