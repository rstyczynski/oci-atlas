/**
 * Usage: npm run example:realms
 * Shows all realms and their keys.
 */
import { gdir_realms_v1 } from "../src";

const client = new gdir_realms_v1();

(async () => {
  const lastUpdated = await client.getLastUpdatedTimestamp();
  console.log("=== Data last updated ===");
  console.log(lastUpdated ?? "(no timestamp — data was not uploaded via tf_manager)");

  const realms    = await client.getRealms();
  const realmKeys = await client.getRealmKeys();

  console.log("\n=== All realms ===");
  console.log(JSON.stringify(realms, null, 2));

  console.log("\n=== Realm keys ===");
  console.log(realmKeys);
})();
