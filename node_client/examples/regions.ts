/** List regions (v2) and tenancy coverage (v1).
 * Usage: TENANCY_KEY=acme_prod npm run example:regions
 */
import { gdir_regions_v2, gdir_tenancies_v1 } from "../src";

const TENANCY_KEY = process.env.TENANCY_KEY ?? "acme_prod";

const regionsClient = new gdir_regions_v2();
const tenanciesClient = new gdir_tenancies_v1({ tenancyKey: TENANCY_KEY });

(async () => {
  console.log("=== Region keys ===");
  console.log(await regionsClient.getRegionKeys());

  console.log("\n=== Realms ===");
  console.log(await regionsClient.getRealms());

  console.log("\n=== Tenancy keys ===");
  console.log(await tenanciesClient.getTenancyKeys());

  console.log("\n=== Tenancy region keys ===");
  console.log(await tenanciesClient.getTenancyRegionKeys());
})();
