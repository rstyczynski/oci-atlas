# Validate regions_v2.json against regions_v2.schema.json before uploading.
data "external" "validate_regions_v2" {
  program = ["bash", "${path.module}/validate.sh"]
  query = {
    schema_file = "${path.module}/regions_v2.schema.json"
    data_file   = "${path.module}/regions_v2.json"
  }
}

resource "oci_objectstorage_object" "v2_regions" {
  bucket       = oci_objectstorage_bucket.info.name
  namespace    = data.oci_objectstorage_namespace.ns.namespace
  object       = "regions/v2"
  content      = jsonencode(merge(jsondecode(file("${path.module}/regions_v2.json")), { last_updated_timestamp = timestamp() }))
  content_type = "application/json"

  depends_on = [data.external.validate_regions_v2]
}

output "regions_v2_object_name" {
  description = "Object path for regions/v2 data in the bucket"
  value       = oci_objectstorage_object.v2_regions.object
}
