output "compartment_id" {
  description = "Effective compartment OCID used (auto-discovered from ~/.oci/config when var.compartment_id is unset)"
  value       = local.effective_compartment_id
}

output "bucket_name" {
  description = "Object Storage bucket name"
  value       = oci_objectstorage_bucket.info.name
}
