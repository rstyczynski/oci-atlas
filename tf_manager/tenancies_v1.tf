# Validate tenancies_v1.json against tenancies_v1.schema.json before uploading.
data "external" "validate_tenancies_v1" {
  program = ["bash", "${path.module}/validate.sh"]
  query = {
    schema_file = "${path.module}/tenancies_v1.schema.json"
    data_file   = "${path.module}/tenancies_v1.json"
  }
}

resource "oci_objectstorage_object" "v1_tenancies" {
  bucket       = oci_objectstorage_bucket.info.name
  namespace    = data.oci_objectstorage_namespace.ns.namespace
  object       = "tenancies/v1"
  content      = jsonencode(merge(jsondecode(file("${path.module}/tenancies_v1.json")), { last_updated_timestamp = timestamp() }))
  content_type = "application/json"

  depends_on = [data.external.validate_tenancies_v1]
}

output "tenancies_v1_object_name" {
  description = "Object path for tenancies/v1 data in the bucket"
  value       = oci_objectstorage_object.v1_tenancies.object
}
