/**
 * Usage: REGION_KEY=eu-zurich-1 TENANCY_KEY=acme_prod npm run example:region
 * Without REGION_KEY the active OCI region from ~/.oci/config is used.
 */
import { gdir_regions_v2, gdir_tenancies_v1 } from "../src";

const REGION_KEY = process.env.REGION_KEY;
const TENANCY_KEY = process.env.TENANCY_KEY ?? "acme_prod";

const regionsClient = new gdir_regions_v2({ regionKey: REGION_KEY });
const tenanciesClient = new gdir_tenancies_v1({ tenancyKey: TENANCY_KEY, regionKey: REGION_KEY });

(async () => {
  // --- region metadata (v2) -------------------------------------------------
  console.log("\n=== Region (v2) ===");
  console.log(await regionsClient.getRegion());

  console.log("\n=== Region short key ===");
  console.log(await regionsClient.getRegionShortKey());

  console.log("\n=== Region realm ===");
  console.log(await regionsClient.getRegionRealm());

  console.log("\n=== Public CIDRs ===");
  console.log(await regionsClient.getRegionCidrPublic());

  // --- tenancy-specific (v1) -----------------------------------------------
  console.log("\n=== Tenancy realm ===");
  console.log(await tenanciesClient.getTenancyRealm());

  console.log("\n=== Network (private CIDRs) ===");
  console.log(await tenanciesClient.getPrivateCidrs());

  console.log("\n=== Proxy ===");
  console.log(await tenanciesClient.getProxy());

  console.log("\n=== GitHub runner labels ===");
  console.log(await tenanciesClient.getGitHubRunnerLabels());

  console.log("\n=== Prometheus scraping CIDR ===");
  console.log(await tenanciesClient.getPromScrapingCidr());
})();
