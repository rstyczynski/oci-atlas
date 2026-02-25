#!/usr/bin/env bash
# gdir_realms_v1.sh — v1 realms schema functions for the global directory.
# Tied to realms/v1 field structure: { [realmKey]: { geo-region, name, description, api_domain } }
# Source this file to get all gdir_v1_realms_* functions.
#
# ENV vars (all optional):
#   GDIR_REALMS_OBJECT — object path override (default: realms/v1)
#   REALM_KEY          — realm key for single-realm functions (e.g. oc1, tst01)

set -euo pipefail

# DAL owns its object path — set before sourcing core so _gdir_fetch uses it.
: "${GDIR_REALMS_OBJECT:=realms/v1}"
: "${GDIR_OBJECT:=$GDIR_REALMS_OBJECT}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/gdir.sh"

# ---------- public API realms/v1 ---------------------------------------------

# ISO 8601 timestamp injected by tf_manager at upload time
gdir_v1_realms_get_last_updated_timestamp() {
  _gdir_fetch
  echo "$_GDIR_CACHE" | jq -r '.last_updated_timestamp // empty'
}

# All realms (pretty JSON), metadata fields excluded
gdir_v1_realms_get_realms() {
  _gdir_fetch
  echo "$_GDIR_CACHE" | jq 'del(.last_updated_timestamp)'
}

# List of realm keys (metadata keys excluded)
gdir_v1_realms_get_realm_keys() {
  _gdir_fetch
  echo "$_GDIR_CACHE" | jq -r 'keys[] | select(. != "last_updated_timestamp")'
}

# Full realm object for REALM_KEY
gdir_v1_realms_get_realm() {
  _gdir_fetch
  echo "$_GDIR_CACHE" | jq --arg k "${REALM_KEY:?REALM_KEY must be set}" '.[$k]'
}

# Deployment model: public | government | sovereign | drcc | alloy | airgapped
gdir_v1_realms_get_realm_type() {
  gdir_v1_realms_get_realm | jq -r '.type'
}

# Realm name, e.g. "OCI Public"
gdir_v1_realms_get_realm_name() {
  gdir_v1_realms_get_realm | jq -r '.name'
}

# Human-readable description
gdir_v1_realms_get_realm_description() {
  gdir_v1_realms_get_realm | jq -r '.description'
}

# Geographic region, e.g. "global", "eu"
gdir_v1_realms_get_realm_geo_region() {
  gdir_v1_realms_get_realm | jq -r '.["geo-region"]'
}

# Base API domain URL for the realm
gdir_v1_realms_get_realm_api_domain() {
  gdir_v1_realms_get_realm | jq -r '.api_domain'
}

# When run directly (not sourced), print all realms
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  gdir_v1_realms_get_realms
fi
