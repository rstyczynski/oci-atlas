# v1 schema — tied to v1 field structure:
# { [realmKey]: { geo-region, name, description, api_domain } }

data "oci_objectstorage_namespace" "ns" {}

data "oci_objectstorage_bucket" "info" {
  namespace = data.oci_objectstorage_namespace.ns.namespace
  name      = var.bucket_name
}
data "oci_objectstorage_object" "realms_v1" {
  namespace = data.oci_objectstorage_namespace.ns.namespace
  bucket    = var.bucket_name
  object    = var.object_name
}

locals {
  realm_key              = var.realm_key
  _raw                   = jsondecode(data.oci_objectstorage_object.realms_v1.content)
  last_updated_timestamp = try(local._raw.last_updated_timestamp, null)
  realms                 = { for k, v in local._raw : k => v if k != "last_updated_timestamp" }

  # ---------------------------------------------------------------------------
  # Single realm
  # ---------------------------------------------------------------------------
  realm = try(local.realms[local.realm_key], null)

  realm_type        = try(local.realms[local.realm_key].type, null)
  realm_name        = try(local.realms[local.realm_key].name, null)
  realm_description = try(local.realms[local.realm_key].description, null)
  realm_geo_region  = try(local.realms[local.realm_key]["geo-region"], null)
  realm_api_domain  = try(local.realms[local.realm_key].api_domain, null)
}
