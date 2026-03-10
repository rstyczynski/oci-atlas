module "tenancies_v1" {
  source       = "../../gdir_tenancies_v1"
  bucket_name  = var.bucket_name
  object_name  = var.tenancies_object
  tenancy_key  = var.tenancy_key
  region_key   = var.region_key
}
