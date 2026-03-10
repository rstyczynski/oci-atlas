// Lists (HCL list(string))
output "region_keys" { value = module.regions_v2.region_keys }
output "realms"      { value = module.regions_v2.realms }
output "tenancy_keys" { value = module.tenancies_v1.tenancy_region_keys }
