/**
 * Usage: REGION_KEY=eu-zurich-1 npm run example:region
 * Without REGION_KEY the active OCI region from ~/.oci/config is used.
 */
import { gdir_regions_v2 } from "../src";

const REGION_KEY = process.env.REGION_KEY;

const regionsClient = new gdir_regions_v2({ regionKey: REGION_KEY });

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
})();
