module "gdir_core" {
  source     = "../.."
  region_key = var.region_key
}

module "gdir_regions_v1" {
  source          = "../../gdir_regions_v1"
  namespace       = module.gdir_core.namespace
  bucket_name     = module.gdir_core.bucket_name
  region_key      = module.gdir_core.region_key
  cidr_tag_filter = var.cidr_tag_filter
}

locals {
  region_key             = module.gdir_core.region_key
  last_updated_timestamp = module.gdir_regions_v1.last_updated_timestamp

  # region
  region                  = module.gdir_regions_v1.region

  # short key
  region_short_key        = module.gdir_regions_v1.region_short_key

  # realm
  realm                   = module.gdir_regions_v1.region_realm
  realm_regions           = module.gdir_regions_v1.realm_regions
  realm_region_keys       = module.gdir_regions_v1.realm_region_keys
  realm_other_regions     = module.gdir_regions_v1.realm_other_regions
  realm_other_region_keys = module.gdir_regions_v1.realm_other_region_keys

  # CIDR
  region_cidr_public   = module.gdir_regions_v1.region_cidr_public
  region_cidr_internal = module.gdir_regions_v1.region_cidr_internal
  region_cidr_by_tag   = module.gdir_regions_v1.region_cidr_by_tag

  # proxy
  region_proxy         = module.gdir_regions_v1.region_proxy
  region_proxy_url     = module.gdir_regions_v1.region_proxy_url
  region_proxy_ip      = module.gdir_regions_v1.region_proxy_ip
  region_proxy_port    = module.gdir_regions_v1.region_proxy_port
  region_proxy_noproxy        = module.gdir_regions_v1.region_proxy_noproxy
  region_proxy_noproxy_string = module.gdir_regions_v1.region_proxy_noproxy_string

  # vault
  region_vault                     = module.gdir_regions_v1.region_vault
  region_vault_ocid                = module.gdir_regions_v1.region_vault_ocid
  region_vault_crypto_endpoint     = module.gdir_regions_v1.region_vault_crypto_endpoint
  region_vault_management_endpoint = module.gdir_regions_v1.region_vault_management_endpoint

  # GitHub
  region_github               = module.gdir_regions_v1.region_github
  region_github_runner        = module.gdir_regions_v1.region_github_runner
  region_github_runner_labels = module.gdir_regions_v1.region_github_runner_labels
  region_github_runner_image  = module.gdir_regions_v1.region_github_runner_image

  # observability
  region_observability      = module.gdir_regions_v1.region_observability
  region_prom_scraping_cidr = module.gdir_regions_v1.region_prom_scraping_cidr
  region_loki_dest_cidr     = module.gdir_regions_v1.region_loki_dest_cidr
  region_loki_fqdn          = module.gdir_regions_v1.region_loki_fqdn

}
