data "oci_objectstorage_namespace" "ns" {}

data "oci_objectstorage_bucket" "info" {
  namespace = data.oci_objectstorage_namespace.ns.namespace
  name      = var.bucket_name
}

data "oci_objectstorage_object" "tenancies_v1" {
  namespace = data.oci_objectstorage_namespace.ns.namespace
  bucket    = var.bucket_name
  object    = var.object_name
}

data "external" "tenancy" {
  program = ["bash", "-c", "oci os ns get-metadata --query '{compartment_id: data.\"default-s3-compartment-id\"}'"]
}

data "oci_identity_tenancy" "current" {
  tenancy_id = data.external.tenancy.result["compartment_id"]
}

locals {
  active_region          = try(split(".", data.oci_objectstorage_bucket.info.bucket_id)[3], null)
  discovered_tenancy_key = try(data.oci_identity_tenancy.current.name, null)
  tenancy_key            = coalesce(var.tenancy_key, local.discovered_tenancy_key)
  region_key             = coalesce(var.region_key, local.active_region)
  _raw                   = jsondecode(data.oci_objectstorage_object.tenancies_v1.content)
  last_updated_timestamp = try(local._raw.last_updated_timestamp, null)
  schema_version         = try(local._raw.schema_version, null)
  tenancies              = { for k, v in local._raw : k => v if !(k == "last_updated_timestamp" || k == "schema_version") }

  tenancy = try(local.tenancies[local.tenancy_key], null)
  realm   = try(local.tenancy.realm, null)

  tenancy_region      = try(local.tenancy.regions[local.region_key], null)
  tenancy_region_keys = try(keys(local.tenancy.regions), [])

  tenancy_region_network = try(local.tenancy_region.network, null)
  tenancy_region_cidr_private = try(local.tenancy_region.network.private, [])
  tenancy_region_cidr_by_tag  = [for entry in local.tenancy_region_cidr_private : entry if contains(entry.tags, var.cidr_tag_filter)]

  tenancy_region_proxy                = try(local.tenancy_region.network.proxy, null)
  tenancy_region_proxy_noproxy        = try(local.tenancy_region_proxy.noproxy, [])
  tenancy_region_proxy_noproxy_string = join(",", local.tenancy_region_proxy_noproxy)

  tenancy_region_vault                 = try(local.tenancy_region.security.vault, null)
  tenancy_region_github                = try(local.tenancy_region.toolchain.github, null)
  tenancy_region_github_runner         = try(local.tenancy_region_github.runner, null)
  tenancy_region_github_runner_labels  = try(local.tenancy_region_github_runner.labels, [])
  tenancy_region_github_runner_image   = try(local.tenancy_region_github_runner.image, null)

  tenancy_region_observability           = try(local.tenancy_region.observability, null)
  tenancy_region_prometheus_scraping_cidr = try(local.tenancy_region_observability.prometheus_scraping_cidr, null)
  tenancy_region_loki_destination_cidr    = try(local.tenancy_region_observability.loki_destination_cidr, null)
  tenancy_region_loki_fqdn                = try(local.tenancy_region_observability.loki_fqdn, null)
}
