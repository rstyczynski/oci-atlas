output "region" { value = module.regions_v2.region }
output "region_cidr_public" { value = module.regions_v2.region_cidr_public }
output "tenancy_region_network" { value = module.tenancies_v1.tenancy_region_network }
output "tenancy_region_proxy" { value = module.tenancies_v1.tenancy_region_proxy }
output "tenancy_region_vault" { value = module.tenancies_v1.tenancy_region_vault }
output "tenancy_region_github_runner" { value = module.tenancies_v1.tenancy_region_github_runner }
output "tenancy_region_observability" { value = module.tenancies_v1.tenancy_region_observability }
