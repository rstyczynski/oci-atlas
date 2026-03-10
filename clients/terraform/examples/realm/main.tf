module "gdir_regions_v2" {
  source      = "../../gdir_regions_v2"
}

locals {
  # Explicit realm_key wins; otherwise derive from the active region's realm field
  effective_realm_key = coalesce(var.realm_key, module.gdir_regions_v2.realm)
}

module "gdir_realms_v1" {
  source      = "../../gdir_realms_v1"
  realm_key   = local.effective_realm_key
}

locals {
  realm_key              = local.effective_realm_key
  last_updated_timestamp = module.gdir_realms_v1.last_updated_timestamp
  realm_type             = module.gdir_realms_v1.realm_type
  realm_name             = module.gdir_realms_v1.realm_name
  realm_description      = module.gdir_realms_v1.realm_description
  realm_geo_region       = module.gdir_realms_v1.realm_geo_region
  realm_api_domain       = module.gdir_realms_v1.realm_api_domain
}
