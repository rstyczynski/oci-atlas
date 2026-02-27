/** List regions (v2).
 * Usage: npm run example:regions
 */
import { gdir_regions_v2 } from "../src";

const regionsClient = new gdir_regions_v2();

(async () => {
  console.log("=== Region keys ===");
  console.log(await regionsClient.getRegionKeys());

  console.log("\n=== Realms ===");
  console.log(await regionsClient.getRealms());
})();
