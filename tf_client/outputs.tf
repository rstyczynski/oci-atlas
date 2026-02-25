output "active_region" {
  description = "OCI region extracted from bucket OCID (raw, before any override)"
  value       = local.active_region
}

output "region_key" {
  description = "Effective region key (var.region_key if set, otherwise active_region)"
  value       = local.region_key
}

output "namespace" {
  description = "OCI Object Storage namespace"
  value       = data.oci_objectstorage_namespace.ns.namespace
}

output "bucket_name" {
  description = "Bucket name — passed to DAL modules so they can fetch their own objects"
  value       = var.bucket_name
}
