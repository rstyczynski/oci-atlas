# Validate realms_v1.json against realms_v1.schema.json before uploading.
data "external" "validate_realms_v1" {
  program = ["bash", "${path.module}/validate.sh"]
  query = {
    schema_file = "${path.module}/realms_v1.schema.json"
    data_file   = "${path.module}/realms_v1.json"
  }
}

resource "oci_objectstorage_object" "v1_realms" {
  bucket       = oci_objectstorage_bucket.info.name
  namespace    = data.oci_objectstorage_namespace.ns.namespace
  object       = "realms/v1"
  content      = jsonencode(merge(jsondecode(file("${path.module}/realms_v1.json")), { last_updated_timestamp = timestamp() }))
  content_type = "application/json"

  depends_on = [data.external.validate_realms_v1]
}

output "realms_object_name" {
  description = "Object path for realms/v1 data in the bucket"
  value       = oci_objectstorage_object.v1_realms.object
}
