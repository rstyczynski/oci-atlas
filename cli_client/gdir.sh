#!/usr/bin/env bash
# gdir.sh — core OCI CLI client for the global directory.
# Schema-independent: handles auth, region discovery, and raw object fetch.
# Source gdir_regions_v1.sh to get gdir_v1_regions_* functions.
#
# ENV vars (all optional):
#   GDIR_BUCKET  — bucket name         (default: gdir_info)
#   GDIR_OBJECT  — object path         (set by DAL, e.g. GDIR_REGIONS_OBJECT in gdir_regions_v1.sh)
#   REGION_KEY   — region key override (default: discovered from bucket OCID)

set -euo pipefail

: "${GDIR_BUCKET:=gdir_info}"

# ---------- cache variables ---------------------------------------------------

_GDIR_CACHE=""
_GDIR_CACHED_REGION_KEY=""
_GDIR_CACHED_REALM=""
_GDIR_CACHED_REALM_FOR=""   # region key for which _GDIR_CACHED_REALM was resolved

# ---------- core helpers ------------------------------------------------------

# Fetch raw JSON from bucket; cached for the shell session.
_gdir_fetch() {
  if [[ -n "$_GDIR_CACHE" ]]; then return; fi
  if [[ -n "${TEST_DATA_DIR:-}" ]]; then
    local fname
    fname=$(echo "$GDIR_OBJECT" | tr '/' '_').json
    local path="$TEST_DATA_DIR/$fname"
    if [[ -f "$path" ]]; then
      _GDIR_CACHE=$(cat "$path")
      return
    fi
  fi
  _GDIR_CACHE=$(oci os object get \
    --bucket-name "$GDIR_BUCKET" \
    --name        "$GDIR_OBJECT" \
    --file        -)
}

# Resolve active region key: REGION_KEY env → extracted from bucket OCID.
# Bucket OCID format: ocid1.bucket.<realm>.<region>.<hash> → field [3].
# Mirrors TF (bucket_id split) and Node (getBucket OCID split).
_gdir_region_key() {
  if [[ -n "${REGION_KEY:-}" ]]; then echo "$REGION_KEY"; return; fi
  if [[ -n "$_GDIR_CACHED_REGION_KEY" ]]; then echo "$_GDIR_CACHED_REGION_KEY"; return; fi
  local ocid
  ocid=$(oci os bucket get --bucket-name "$GDIR_BUCKET" --query 'data.id' --raw-output)
  if [[ -z "$ocid" ]]; then
    echo "Error: REGION_KEY not set and could not read bucket OCID" >&2; return 1
  fi
  # ocid1.bucket.<realm>.<region>.<hash>  →  split on '.' → index 3
  _GDIR_CACHED_REGION_KEY=$(echo "$ocid" | awk -F'.' '{print $4}')
  echo "$_GDIR_CACHED_REGION_KEY"
}

# Resolve and cache the realm of the active region (reads directly from cache).
# Cache is keyed by region — invalidated automatically when REGION_KEY changes.
_gdir_resolve_realm() {
  local key; key=$(_gdir_region_key)
  if [[ -n "$_GDIR_CACHED_REALM" && "$_GDIR_CACHED_REALM_FOR" == "$key" ]]; then
    echo "$_GDIR_CACHED_REALM"; return
  fi
  _gdir_fetch
  _GDIR_CACHED_REALM=$(echo "$_GDIR_CACHE" | jq -r --arg k "$key" '.[$k].realm')
  _GDIR_CACHED_REALM_FOR="$key"
  echo "$_GDIR_CACHED_REALM"
}

# When run directly (not sourced), print active region key and raw object.
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  echo "Region key: $(_gdir_region_key)"
  _gdir_fetch
  echo "$_GDIR_CACHE"
fi
