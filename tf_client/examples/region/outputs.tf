output "last_updated_timestamp" {
  description = "Timestamp when the data was last uploaded by tf_manager"
  value       = local.last_updated_timestamp
}

output "region_key" {
  description = "Effective region key (auto-detected or overridden via TF_VAR_region_key)"
  value       = local.region_key
}

output "region" {
  description = "One region object (v1 schema)"
  value       = local.region
}

# ---------------------------------------------------------------------------
# Short key
# ---------------------------------------------------------------------------

output "region_short_key" {
  description = "Short region code, e.g. ZRH, FRA (v1 schema)"
  value       = local.region_short_key
}

# ---------------------------------------------------------------------------
# Realm
# ---------------------------------------------------------------------------

output "realm" {
  description = "Realm for the selected region (v1 schema)"
  value       = local.realm
}

output "realm_regions" {
  description = "All regions in the same realm (v1 schema)"
  value       = local.realm_regions
}

output "realm_region_keys" {
  description = "Keys of all regions in the same realm (v1 schema)"
  value       = local.realm_region_keys
}

output "realm_other_regions" {
  description = "Regions in the same realm, excluding active region (v1 schema)"
  value       = local.realm_other_regions
}

output "realm_other_region_keys" {
  description = "Keys of other regions in the same realm (v1 schema)"
  value       = local.realm_other_region_keys
}

# ---------------------------------------------------------------------------
# CIDR
# ---------------------------------------------------------------------------

output "region_cidr_public" {
  description = "Public CIDR entries (v1 schema)"
  value       = local.region_cidr_public
}

output "region_cidr_internal" {
  description = "Internal CIDR entries (v1 schema)"
  value       = local.region_cidr_internal
}

output "region_cidr_by_tag" {
  description = "CIDR entries matching var.cidr_tag_filter (v1 schema)"
  value       = local.region_cidr_by_tag
}

# ---------------------------------------------------------------------------
# Proxy
# ---------------------------------------------------------------------------

output "region_proxy" {
  description = "Proxy object — url, ip, port, noproxy (v1 schema)"
  value       = local.region_proxy
}

output "region_proxy_url" {
  description = "Proxy URL (v1 schema)"
  value       = local.region_proxy_url
}

output "region_proxy_ip" {
  description = "Proxy IP (v1 schema)"
  value       = local.region_proxy_ip
}

output "region_proxy_port" {
  description = "Proxy port (v1 schema)"
  value       = local.region_proxy_port
}

output "region_proxy_noproxy" {
  description = "No-proxy list (v1 schema)"
  value       = local.region_proxy_noproxy
}

output "region_proxy_noproxy_string" {
  description = "No-proxy list as a comma-separated string — ready for NO_PROXY env var (v1 schema)"
  value       = local.region_proxy_noproxy_string
}

# ---------------------------------------------------------------------------
# Vault
# ---------------------------------------------------------------------------

output "region_vault" {
  description = "Full vault object (v1 schema)"
  value       = local.region_vault
}

output "region_vault_ocid" {
  description = "Vault OCID (v1 schema)"
  value       = local.region_vault_ocid
}

output "region_vault_crypto_endpoint" {
  description = "Vault cryptographic operations endpoint (v1 schema)"
  value       = local.region_vault_crypto_endpoint
}

output "region_vault_management_endpoint" {
  description = "Vault management endpoint (v1 schema)"
  value       = local.region_vault_management_endpoint
}

# ---------------------------------------------------------------------------
# GitHub
# ---------------------------------------------------------------------------

output "region_github" {
  description = "Full GitHub object (v1 schema)"
  value       = local.region_github
}

output "region_github_runner" {
  description = "Full GitHub runner object (v1 schema)"
  value       = local.region_github_runner
}

output "region_github_runner_labels" {
  description = "GitHub Actions runner labels for this region (v1 schema)"
  value       = local.region_github_runner_labels
}

output "region_github_runner_image" {
  description = "Compute image OCID used for GitHub runner instances (v1 schema)"
  value       = local.region_github_runner_image
}

# ---------------------------------------------------------------------------
# Observability
# ---------------------------------------------------------------------------

output "region_observability" {
  description = "Full observability object (v1 schema)"
  value       = local.region_observability
}

output "region_prom_scraping_cidr" {
  description = "CIDR allowed to scrape Prometheus (v1 schema)"
  value       = local.region_prom_scraping_cidr
}

output "region_loki_dest_cidr" {
  description = "CIDR of the Loki destination (v1 schema)"
  value       = local.region_loki_dest_cidr
}

output "region_loki_fqdn" {
  description = "FQDN of the Loki endpoint (v1 schema)"
  value       = local.region_loki_fqdn
}

# ---------------------------------------------------------------------------
# Image
# ---------------------------------------------------------------------------

