module "regions_v2" {
  source       = "../../gdir_regions_v2"
  namespace    = var.namespace
  bucket_name  = var.bucket_name
  object_name  = var.regions_object
  region_key   = var.region_key
}

module "tenancies_v1" {
  source       = "../../gdir_tenancies_v1"
  namespace    = var.namespace
  bucket_name  = var.bucket_name
  object_name  = var.tenancies_object
  tenancy_key  = var.tenancy_key
  region_key   = var.region_key
}
