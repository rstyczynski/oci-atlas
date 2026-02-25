import { gdir_regions_v1 } from "../src";

const client = new gdir_regions_v1();

(async () => {
  // --- document metadata ---------------------------------------------------
  const lastUpdated = await client.getLastUpdatedTimestamp();
  console.log("=== Data last updated ===");
  console.log(lastUpdated ?? "(no timestamp — data was not uploaded via tf_manager)");

  // --- map-level -----------------------------------------------------------
  const regions    = await client.getRegions();
  const regionKeys = await client.getRegionKeys();
  const realms     = await client.getRealms();

  console.log("\n=== All regions ===");
  console.log(JSON.stringify(regions, null, 2));

  console.log("\n=== Region keys ===");
  console.log(regionKeys);

  console.log("\n=== Realms ===");
  console.log(realms);

  // --- per-realm breakdown --------------------------------------------------
  for (const realm of realms) {
    const allRegions = await client.getRegions();
    const realmKey = Object.keys(allRegions).find(k => allRegions[k].realm === realm);
    if (!realmKey) continue;

    const realmClient  = new gdir_regions_v1({ regionKey: realmKey });
    const realmRegions = await realmClient.getRealmRegions();
    const realmKeys    = await realmClient.getRealmRegionKeys();

    console.log(`\n=== Realm: ${realm} — region keys ===`);
    console.log(realmKeys);

    console.log(`\n=== Realm: ${realm} — regions ===`);
    console.log(JSON.stringify(realmRegions, null, 2));
  }

  // --- per-region field summary ---------------------------------------------
  console.log("\n=== Per-region field summary ===");
  for (const key of regionKeys) {
    const rc = new gdir_regions_v1({ regionKey: key });

    const shortKey     = await rc.getRegionShortKey();
    const realm        = await rc.getRegionRealm();
    const cidrPublic   = await rc.getRegionCidrPublic();
    const cidrInternal = await rc.getRegionCidrInternal();
    const proxyIp      = await rc.getRegionProxyIp();
    const proxyPort    = await rc.getRegionProxyPort();
    const noproxy       = await rc.getRegionProxyNoproxy();
    const noproxyStr    = await rc.getRegionProxyNoproxyString();
    const vaultOcid    = await rc.getRegionVaultOcid();
    const runnerLabels  = await rc.getRegionGitHubRunnerLabels();
    const runnerImage   = await rc.getRegionGitHubRunnerImage();
    const promCidr     = await rc.getRegionPromScrapingCidr();
    const lokiFqdn     = await rc.getRegionLokiFqdn();

    console.log(`\n[${key}]`);
    console.log(`  short key        : ${shortKey}`);
    console.log(`  realm            : ${realm}`);
    console.log(`  CIDR public      : ${cidrPublic.map(e => e.cidr).join(", ")}`);
    console.log(`  CIDR internal    : ${cidrInternal.map(e => e.cidr).join(", ")}`);
    console.log(`  proxy            : ${proxyIp}:${proxyPort}`);
    console.log(`  noproxy          : ${noproxy.join(", ")}`);
    console.log(`  NO_PROXY string  : ${noproxyStr}`);
    console.log(`  vault            : ${vaultOcid}`);
    console.log(`  runner labels    : ${runnerLabels.join(", ")}`);
    console.log(`  runner image     : ${runnerImage}`);
    console.log(`  prom scrape CIDR : ${promCidr}`);
    console.log(`  loki fqdn        : ${lokiFqdn}`);
  }
})();
