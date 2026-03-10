/** Tenancy-focused example (tenancies/v1)
 * Usage:
 *   npm run example:tenancy
 *   TENANCY_KEY=demo_corp REGION_KEY=tst-region-1 npm run example:tenancy
 */
import { gdir_tenancies_v1 } from "../src";

const TENANCY_KEY = process.env.TENANCY_KEY;
const REGION_KEY  = process.env.REGION_KEY;

const client = new gdir_tenancies_v1({ tenancyKey: TENANCY_KEY, regionKey: REGION_KEY });

(async () => {
  console.log("=== Proxy URL ===");
  console.log(await client.getProxyUrl());

  console.log("\n=== Vault OCID ===");
  console.log(await client.getVaultOcid());

  console.log("\n=== Private CIDRs ===");
  console.log(await client.getPrivateCidrs());

  console.log("\n=== Proxy no-proxy entries ===");
  console.log(await client.getProxyNoproxy());

  console.log("\n=== Proxy no-proxy string ===");
  console.log(await client.getProxyNoproxyString());
})();
