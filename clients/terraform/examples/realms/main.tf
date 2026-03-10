module "gdir_realms_v1" {
  source      = "../../gdir_realms_v1"
}

locals {
  realms     = module.gdir_realms_v1.realms
  realm_keys = module.gdir_realms_v1.realm_keys
}
