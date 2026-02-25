# v1 schema — tied to v1 field structure:
# { [regionKey]: { key, realm, network: { public, internal, proxy }, security: { vault }, toolchain: { github }, observability } }

data "oci_objectstorage_object" "regions_v1" {
  namespace = var.namespace
  bucket    = var.bucket_name
  object    = var.object_name
}

locals {
  region_key             = var.region_key
  _raw                   = jsondecode(data.oci_objectstorage_object.regions_v1.content)
  last_updated_timestamp = try(local._raw.last_updated_timestamp, null)
  regions                = { for k, v in local._raw : k => v if k != "last_updated_timestamp" }

  # ---------------------------------------------------------------------------
  # Single region
  # ---------------------------------------------------------------------------
  region = try(local.regions[local.region_key], null)

  # ---------------------------------------------------------------------------
  # Short key
  # ---------------------------------------------------------------------------
  region_short_key = try(local.regions[local.region_key].key, null)

  # ---------------------------------------------------------------------------
  # Realm
  # ---------------------------------------------------------------------------
  region_realm = try(local.regions[local.region_key].realm, null)

  realms = distinct([for r in values(local.regions) : r.realm])

  realm_regions = {
    for k, v in local.regions : k => v
    if v.realm == local.region_realm
  }
  realm_region_keys = keys(local.realm_regions)

  realm_other_regions = {
    for k, v in local.regions : k => v
    if v.realm == local.region_realm && k != local.region_key
  }
  realm_other_region_keys = keys(local.realm_other_regions)

  # ---------------------------------------------------------------------------
  # Network (CIDR + proxy)
  # ---------------------------------------------------------------------------
  region_network = try(local.regions[local.region_key].network, null)

  # ---------------------------------------------------------------------------
  # CIDR
  # ---------------------------------------------------------------------------
  region_cidr_public   = try(local.regions[local.region_key].network.public, [])
  region_cidr_internal = try(local.regions[local.region_key].network.internal, [])

  # All CIDR entries (public + internal) matching a given tag — filter via tag variable
  region_cidr_by_tag = {
    for entry in concat(local.region_cidr_public, local.region_cidr_internal) :
    entry.cidr => entry
    if contains(entry.tags, var.cidr_tag_filter)
  }

  # ---------------------------------------------------------------------------
  # Proxy
  # ---------------------------------------------------------------------------
  region_proxy         = try(local.regions[local.region_key].network.proxy, null)
  region_proxy_url     = try(local.regions[local.region_key].network.proxy.url, null)
  region_proxy_ip      = try(local.regions[local.region_key].network.proxy.ip, null)
  region_proxy_port    = try(local.regions[local.region_key].network.proxy.port, null)
  region_proxy_noproxy        = try(local.regions[local.region_key].network.proxy.noproxy, [])
  region_proxy_noproxy_string = join(",", try(local.regions[local.region_key].network.proxy.noproxy, []))

  # ---------------------------------------------------------------------------
  # Security (vault)
  # ---------------------------------------------------------------------------
  region_security = try(local.regions[local.region_key].security, null)

  # ---------------------------------------------------------------------------
  # Vault
  # ---------------------------------------------------------------------------
  region_vault                      = try(local.regions[local.region_key].security.vault, null)
  region_vault_ocid                 = try(local.regions[local.region_key].security.vault.ocid, null)
  region_vault_crypto_endpoint      = try(local.regions[local.region_key].security.vault.crypto_endpoint, null)
  region_vault_management_endpoint  = try(local.regions[local.region_key].security.vault.management_endpoint, null)

  # ---------------------------------------------------------------------------
  # Toolchain
  # ---------------------------------------------------------------------------
  region_toolchain            = try(local.regions[local.region_key].toolchain, null)
  region_github               = try(local.regions[local.region_key].toolchain.github, null)
  region_github_runner        = try(local.regions[local.region_key].toolchain.github.runner, null)
  region_github_runner_labels = try(local.regions[local.region_key].toolchain.github.runner.labels, [])
  region_github_runner_image  = try(local.regions[local.region_key].toolchain.github.runner.image, null)

  # ---------------------------------------------------------------------------
  # Observability
  # ---------------------------------------------------------------------------
  region_observability         = try(local.regions[local.region_key].observability, null)
  region_prom_scraping_cidr    = try(local.regions[local.region_key].observability.prometheus_scraping_cidr, null)
  region_loki_dest_cidr        = try(local.regions[local.region_key].observability.loki_destination_cidr, null)
  region_loki_fqdn             = try(local.regions[local.region_key].observability.loki_fqdn, null)

}
