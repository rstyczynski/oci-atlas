#!/usr/bin/env bash
# Mirrors node_client/examples/client_region.ts
# Usage: REGION_KEY=eu-zurich-1 bash examples/region.sh
#        Without REGION_KEY the active OCI region from ~/.oci/config is used.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../gdir_regions_v1.sh"

RESOLVED_KEY=$(_gdir_region_key)

# --- short key ---------------------------------------------------------------
echo "=== Short key ==="
gdir_v1_regions_get_region_short_key

# --- realm -------------------------------------------------------------------
echo ""
echo "=== Realm ==="
gdir_v1_regions_get_region_realm

echo ""
echo "=== Realm region keys ==="
gdir_v1_regions_get_realm_region_keys

echo ""
echo "=== Realm regions ==="
gdir_v1_regions_get_realm_regions

echo ""
echo "=== Realm other region keys (excluding $RESOLVED_KEY) ==="
gdir_v1_regions_get_realm_other_region_keys

echo ""
echo "=== Realm other regions (excluding $RESOLVED_KEY) ==="
gdir_v1_regions_get_realm_other_regions

# --- region ------------------------------------------------------------------
echo ""
echo "=== Region: $RESOLVED_KEY ==="
gdir_v1_regions_get_region

# --- CIDR --------------------------------------------------------------------
echo ""
echo "=== CIDR — public ==="
gdir_v1_regions_get_region_cidr_public

echo ""
echo "=== CIDR — internal ==="
gdir_v1_regions_get_region_cidr_internal

echo ""
echo "=== CIDR — by tag: OCI ==="
gdir_v1_regions_get_region_cidr_by_tag OCI

echo ""
echo "=== CIDR — by tag: OSN ==="
gdir_v1_regions_get_region_cidr_by_tag OSN

echo ""
echo "=== CIDR — by tag: vcn ==="
gdir_v1_regions_get_region_cidr_by_tag vcn

# --- proxy -------------------------------------------------------------------
echo ""
echo "=== Proxy ==="
gdir_v1_regions_get_region_proxy

echo ""
echo "=== Proxy URL ==="
gdir_v1_regions_get_region_proxy_url

echo ""
echo "=== Proxy IP ==="
gdir_v1_regions_get_region_proxy_ip

echo ""
echo "=== Proxy port ==="
gdir_v1_regions_get_region_proxy_port

echo ""
echo "=== Proxy noproxy (list) ==="
gdir_v1_regions_get_region_proxy_noproxy

echo ""
echo "=== Proxy noproxy (NO_PROXY string) ==="
gdir_v1_regions_get_region_proxy_noproxy_string

# --- vault -------------------------------------------------------------------
echo ""
echo "=== Vault ==="
gdir_v1_regions_get_region_vault

echo ""
echo "=== Vault OCID ==="
gdir_v1_regions_get_region_vault_ocid

echo ""
echo "=== Vault crypto endpoint ==="
gdir_v1_regions_get_region_vault_crypto_endpoint

echo ""
echo "=== Vault management endpoint ==="
gdir_v1_regions_get_region_vault_management_endpoint

# --- GitHub ------------------------------------------------------------------
echo ""
echo "=== GitHub runner ==="
gdir_v1_regions_get_region_github_runner

echo ""
echo "=== GitHub runner labels ==="
gdir_v1_regions_get_region_github_runner_labels

echo ""
echo "=== GitHub runner image ==="
gdir_v1_regions_get_region_github_runner_image

# --- observability -----------------------------------------------------------
echo ""
echo "=== Observability ==="
gdir_v1_regions_get_region_observability

echo ""
echo "=== Prometheus scraping CIDR ==="
gdir_v1_regions_get_region_prom_scraping_cidr

echo ""
echo "=== Loki destination CIDR ==="
gdir_v1_regions_get_region_loki_dest_cidr

echo ""
echo "=== Loki FQDN ==="
gdir_v1_regions_get_region_loki_fqdn
