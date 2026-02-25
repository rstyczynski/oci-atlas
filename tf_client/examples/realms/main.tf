module "gdir_core" {
  source = "../.."
}

module "gdir_realms_v1" {
  source      = "../../gdir_realms_v1"
  namespace   = module.gdir_core.namespace
  bucket_name = module.gdir_core.bucket_name
}

locals {
  last_updated_timestamp = module.gdir_realms_v1.last_updated_timestamp
  realms     = module.gdir_realms_v1.realms
  realm_keys = module.gdir_realms_v1.realm_keys
}
