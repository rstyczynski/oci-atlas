data "oci_objectstorage_namespace" "ns" {}

data "oci_objectstorage_bucket" "info" {
  namespace = data.oci_objectstorage_namespace.ns.namespace
  name      = var.bucket_name
}

data "oci_objectstorage_object" "regions_v2" {
  namespace = data.oci_objectstorage_namespace.ns.namespace
  bucket    = var.bucket_name
  object    = var.object_name
}

locals {
  active_region          = try(split(".", data.oci_objectstorage_bucket.info.bucket_id)[3], null)
  region_key             = coalesce(var.region_key, local.active_region)
  _raw                   = jsondecode(data.oci_objectstorage_object.regions_v2.content)
  schema_version         = try(local._raw.schema_version, null)
  regions                = { for k, v in local._raw : k => v if !(k == "schema_version") }

  region = try(local.regions[local.region_key], null)
  realm = try(local.region.realm, null)
  region_short_key = try(local.region.key, null)
  
  realm_regions = {
    for k, v in local.regions : k => v
    if v.realm == try(local.region.realm, null)
  }
  realm_region_keys       = keys(local.realm_regions)
  realm_other_regions     = { for k, v in local.realm_regions : k => v if k != local.region_key }
  realm_other_region_keys = keys(local.realm_other_regions)

  # Distinct realm keys (same as CLI get_realms: to_entries | map(.value.realm) | unique)
  realms = distinct([for v in local.regions : v.realm])

  # Network CIDRs — align types with CLI:
  # - CLI raw lines: list of CIDR strings
  # - Terraform: HCL list(string), full objects available via `region` output
  region_cidr_public_entries = try(local.region.network.public, [])
  region_cidr_public         = [for entry in local.region_cidr_public_entries : entry.cidr]
  region_cidr_by_tag         = [
    for entry in local.region_cidr_public_entries : entry.cidr
    if contains(entry.tags, var.cidr_tag_filter)
  ]
}
