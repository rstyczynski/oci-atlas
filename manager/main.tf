data "oci_objectstorage_namespace" "ns" {}

// the only way to get tenancy ocid from current connection
// requires TF to work with process' OCI SDK credentials
// raw: oci os ns get-metadata --query '{compartment_id: data."default-s3-compartment-id"}'
data "external" "tenancy" {
  program = ["bash", "-c", "oci os ns get-metadata --query '{compartment_id: data.\"default-s3-compartment-id\"}'"]
}

locals {
  effective_compartment_id = coalesce(var.compartment_id, data.external.tenancy.result["compartment_id"])
}

resource "oci_objectstorage_bucket" "info" {
  compartment_id = local.effective_compartment_id
  namespace      = data.oci_objectstorage_namespace.ns.namespace
  name           = var.bucket_name
  access_type    = "NoPublicAccess"
  versioning     = "Enabled"

  dynamic "retention_rules" {
    for_each = var.enable_retention ? [1] : []
    content {
      display_name = "read-only-retention"
      duration {
        time_amount = var.retention_time_amount
        time_unit   = var.retention_time_unit
      }
      time_rule_locked = var.retention_rule_locked
    }
  }
}
