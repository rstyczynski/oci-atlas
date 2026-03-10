module "regions_v2" {
  source       = "../../gdir_regions_v2"
  bucket_name  = var.bucket_name
  object_name  = var.regions_object
  region_key   = var.region_key
}

