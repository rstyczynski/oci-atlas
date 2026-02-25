data "oci_objectstorage_namespace" "ns" {}

data "oci_objectstorage_bucket" "info" {
  namespace = data.oci_objectstorage_namespace.ns.namespace
  name      = var.bucket_name
}

locals {
  # Schema-independent: region discovery
  # OCID format: ocid1.bucket.<realm>.<region>.<hash> → split(".")[3]
  active_region = split(".", data.oci_objectstorage_bucket.info.bucket_id)[3]
  region_key    = coalesce(var.region_key, local.active_region)
}
