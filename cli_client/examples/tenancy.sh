#!/usr/bin/env bash
# Usage: TENANCY_KEY=acme_prod REGION_KEY=eu-zurich-1 bash examples/tenancy.sh
set -euo pipefail

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$BASE_DIR/gdir_tenancies_v1.sh"

: "${TENANCY_KEY:?TENANCY_KEY required}"
: "${REGION_KEY:=}" # optional; auto-resolves if unset

echo "=== Tenancy keys ==="
gdir_v1_tenancies_get_tenancy_keys

echo "\n=== Tenancy realm ==="
gdir_v1_tenancies_get_tenancy_realm

echo "\n=== Region keys for tenancy ==="
gdir_v1_tenancies_get_tenancy_region_keys

echo "\n=== Network (private CIDRs) ==="
gdir_v1_tenancies_get_tenancy_region_cidr_private

echo "\n=== Proxy ==="
gdir_v1_tenancies_get_tenancy_region_proxy

echo "\n=== Vault ==="
gdir_v1_tenancies_get_tenancy_region_vault

echo "\n=== GitHub runner labels ==="
gdir_v1_tenancies_get_tenancy_region_github_runner_labels

echo "\n=== Observability (Prometheus scraping CIDR) ==="
gdir_v1_tenancies_get_tenancy_region_prom_scraping_cidr
