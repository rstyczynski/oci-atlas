/**
 * Usage: npm run example:realm
 *        REALM_KEY=oc1 npm run example:realm
 * Without REALM_KEY the realm is auto-discovered from the active region's
 * `realm` field (same discovery chain as `region` → OCI bucket OCID).
 */
import { gdir_regions_v2, gdir_realms_v1 } from "../src";

(async () => {
  // --- resolve realm key -------------------------------------------------------
  // Explicit env override, or discover from the active region's realm field.
  const realmKey = process.env.REALM_KEY ?? await new gdir_regions_v2().getRegionRealm();

  console.log("=== Realm key ===");
  console.log(realmKey);

  // --- realm data --------------------------------------------------------------
  const client = new gdir_realms_v1({ realmKey });

  const lastUpdated = await client.getLastUpdatedTimestamp();
  console.log("\n=== Data last updated ===");
  console.log(lastUpdated ?? "(no timestamp — data was not uploaded via tf_manager)");

  const realm       = await client.getRealm();
  const realmType   = await client.getRealmType();
  const name        = await client.getRealmName();
  const description = await client.getRealmDescription();
  const geoRegion   = await client.getRealmGeoRegion();
  const apiDomain   = await client.getRealmApiDomain();

  console.log(`\n=== Realm: ${realmKey} ===`);
  console.log(JSON.stringify(realm, null, 2));

  console.log("\n=== Field summary ===");
  console.log(`  type        : ${realmType}`);
  console.log(`  name        : ${name}`);
  console.log(`  description : ${description}`);
  console.log(`  geo-region  : ${geoRegion}`);
  console.log(`  api_domain  : ${apiDomain}`);
})();
