/** Tenancy-focused example (tenancies/v1)
 * Usage: TENANCY_KEY=acme_prod REGION_KEY=eu-zurich-1 npm run example:tenancy
 */
import { gdir_tenancies_v1 } from "../src";

const TENANCY_KEY = process.env.TENANCY_KEY ?? "acme_prod";
const REGION_KEY  = process.env.REGION_KEY;

const client = new gdir_tenancies_v1({ tenancyKey: TENANCY_KEY, regionKey: REGION_KEY });

(async () => {
  console.log("=== Tenancy realm ===");
  console.log(await client.getTenancyRealm());

  console.log("\n=== Region keys ===");
  console.log(await client.getTenancyRegionKeys());

  console.log("\n=== Network (private CIDRs) ===");
  console.log(await client.getPrivateCidrs());

  console.log("\n=== Proxy ===");
  console.log(await client.getProxy());

  console.log("\n=== GitHub runner labels ===");
  console.log(await client.getGitHubRunnerLabels());

  console.log("\n=== Prometheus scraping CIDR ===");
  console.log(await client.getPromScrapingCidr());
})();
