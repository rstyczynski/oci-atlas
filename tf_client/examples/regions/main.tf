module "gdir_core" {
  source = "../.."
}

module "gdir_regions_v1" {
  source      = "../../gdir_regions_v1"
  namespace   = module.gdir_core.namespace
  bucket_name = module.gdir_core.bucket_name
  region_key  = module.gdir_core.region_key
}

locals {
  last_updated_timestamp = module.gdir_regions_v1.last_updated_timestamp
  regions     = module.gdir_regions_v1.regions
  region_keys = module.gdir_regions_v1.region_keys
  realms      = module.gdir_regions_v1.realms
}
