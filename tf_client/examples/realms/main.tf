module "gdir_realms_v1" {
  source      = "../../gdir_realms_v1"
}

locals {
  last_updated_timestamp = module.gdir_realms_v1.last_updated_timestamp
  realms     = module.gdir_realms_v1.realms
  realm_keys = module.gdir_realms_v1.realm_keys
}
