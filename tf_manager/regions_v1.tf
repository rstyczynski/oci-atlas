# Validate regions_v1.json against regions_v1.schema.json before uploading.
data "external" "validate_regions_v1" {
  program = ["bash", "${path.module}/validate.sh"]
  query = {
    schema_file = "${path.module}/regions_v1.schema.json"
    data_file   = "${path.module}/regions_v1.json"
  }
}

resource "oci_objectstorage_object" "v1_regions" {
  bucket       = oci_objectstorage_bucket.info.name
  namespace    = data.oci_objectstorage_namespace.ns.namespace
  object       = "regions/v1"
  content      = jsonencode(merge(jsondecode(file("${path.module}/regions_v1.json")), { last_updated_timestamp = timestamp() }))
  content_type = "application/json"

  # Upload only after validation passes
  depends_on = [data.external.validate_regions_v1]
}

output "regions_object_name" {
  description = "Object path for regions/v1 data in the bucket"
  value       = oci_objectstorage_object.v1_regions.object
}
