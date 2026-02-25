/**
 * Usage: REGION_KEY=eu-zurich-1 npm run example:region
 * Without REGION_KEY the active OCI region from ~/.oci/config is used.
 */
import { gdir_regions_v1 } from "../src";

const REGION_KEY = process.env.REGION_KEY;

const client = REGION_KEY
  ? new gdir_regions_v1({ regionKey: REGION_KEY })
  : new gdir_regions_v1();

(async () => {
  // --- short key -------------------------------------------------------------
  const shortKey = await client.getRegionShortKey();

  console.log("\n=== Short key ===");
  console.log(shortKey);

  // --- realm -----------------------------------------------------------------
  const realm           = await client.getRegionRealm();
  const realmRegions    = await client.getRealmRegions();
  const realmKeys       = await client.getRealmRegionKeys();
  const otherRegions    = await client.getRealmOtherRegions();
  const otherRegionKeys = await client.getRealmOtherRegionKeys();

  console.log("\n=== Realm ===");
  console.log(realm);
  console.log(`\n=== Realm: ${realm} — region keys ===`);
  console.log(realmKeys);
  console.log(`\n=== Realm: ${realm} — regions ===`);
  console.log(JSON.stringify(realmRegions, null, 2));
  console.log(`\n=== Realm: ${realm} — other region keys ===`);
  console.log(otherRegionKeys);
  console.log(`\n=== Realm: ${realm} — other regions ===`);
  console.log(JSON.stringify(otherRegions, null, 2));

  // --- region ----------------------------------------------------------------
  const region = await client.getRegion();
  console.log(`\n=== Region: ${REGION_KEY ?? "auto"} ===`);
  console.log(JSON.stringify(region, null, 2));

  // --- CIDR ------------------------------------------------------------------
  const cidrPublic   = await client.getRegionCidrPublic();
  const cidrInternal = await client.getRegionCidrInternal();
  const cidrOci      = await client.getRegionCidrByTag("OCI");
  const cidrOsn      = await client.getRegionCidrByTag("OSN");
  const cidrVcn      = await client.getRegionCidrByTag("vcn");

  console.log("\n=== CIDR — public ===");
  console.log(JSON.stringify(cidrPublic, null, 2));
  console.log("\n=== CIDR — internal ===");
  console.log(JSON.stringify(cidrInternal, null, 2));
  console.log("\n=== CIDR — by tag: OCI ===");
  console.log(JSON.stringify(cidrOci, null, 2));
  console.log("\n=== CIDR — by tag: OSN ===");
  console.log(JSON.stringify(cidrOsn, null, 2));
  console.log("\n=== CIDR — by tag: vcn ===");
  console.log(JSON.stringify(cidrVcn, null, 2));

  // --- proxy -----------------------------------------------------------------
  const proxy              = await client.getRegionProxy();
  const proxyUrl           = await client.getRegionProxyUrl();
  const proxyIp            = await client.getRegionProxyIp();
  const proxyPort          = await client.getRegionProxyPort();
  const proxyNoproxy       = await client.getRegionProxyNoproxy();
  const proxyNoproxyString = await client.getRegionProxyNoproxyString();

  console.log("\n=== Proxy ===");
  console.log(JSON.stringify(proxy, null, 2));
  console.log("\n=== Proxy URL ===");
  console.log(proxyUrl);
  console.log("\n=== Proxy IP ===");
  console.log(proxyIp);
  console.log("\n=== Proxy port ===");
  console.log(proxyPort);
  console.log("\n=== Proxy noproxy (list) ===");
  console.log(proxyNoproxy);
  console.log("\n=== Proxy noproxy (NO_PROXY string) ===");
  console.log(proxyNoproxyString);

  // --- vault -----------------------------------------------------------------
  const vault                    = await client.getRegionVault();
  const vaultOcid                = await client.getRegionVaultOcid();
  const vaultCryptoEndpoint      = await client.getRegionVaultCryptoEndpoint();
  const vaultManagementEndpoint  = await client.getRegionVaultManagementEndpoint();

  console.log("\n=== Vault ===");
  console.log(JSON.stringify(vault, null, 2));
  console.log("\n=== Vault OCID ===");
  console.log(vaultOcid);
  console.log("\n=== Vault crypto endpoint ===");
  console.log(vaultCryptoEndpoint);
  console.log("\n=== Vault management endpoint ===");
  console.log(vaultManagementEndpoint);

  // --- GitHub ----------------------------------------------------------------
  const gitHubRunner      = await client.getRegionGitHubRunner();
  const runnerLabels      = await client.getRegionGitHubRunnerLabels();
  const runnerImage       = await client.getRegionGitHubRunnerImage();

  console.log("\n=== GitHub runner ===");
  console.log(JSON.stringify(gitHubRunner, null, 2));
  console.log("\n=== GitHub runner labels ===");
  console.log(runnerLabels);
  console.log("\n=== GitHub runner image ===");
  console.log(runnerImage);

  // --- observability ---------------------------------------------------------
  const observability   = await client.getRegionObservability();
  const promCidr        = await client.getRegionPromScrapingCidr();
  const lokiDestCidr    = await client.getRegionLokiDestCidr();
  const lokiFqdn        = await client.getRegionLokiFqdn();

  console.log("\n=== Observability ===");
  console.log(JSON.stringify(observability, null, 2));
  console.log("\n=== Prometheus scraping CIDR ===");
  console.log(promCidr);
  console.log("\n=== Loki destination CIDR ===");
  console.log(lokiDestCidr);
  console.log("\n=== Loki FQDN ===");
  console.log(lokiFqdn);

})();
