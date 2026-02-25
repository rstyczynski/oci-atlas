/**
 * Jest tests — no OCI connectivity required.
 * MockRegions / MockRealms override fetchObject() to read local JSON test data.
 *
 * Run: npm run test:jest
 *      TEST_DATA_DIR=/path/to/tf_manager npm run test:jest
 */
import * as fs   from "fs";
import * as path from "path";

import { gdir_config }                       from "../src/config";
import { gdir_regions_v1 }                   from "../src/gdir_regions_v1";
import { gdir_realms_v1, gdir_realms_config } from "../src/gdir_realms_v1";

const TEST_DATA_DIR = process.env.TEST_DATA_DIR
  ?? path.resolve(__dirname, "../../tf_manager");

// ---------------------------------------------------------------------------
// Mock subclasses
// ---------------------------------------------------------------------------

class MockRegions extends gdir_regions_v1 {
  constructor(config: gdir_config = {}) { super(config); }
  protected override async fetchObject(): Promise<string> {
    return fs.readFileSync(path.join(TEST_DATA_DIR, "regions_v1.json"), "utf8");
  }
}

class MockRealms extends gdir_realms_v1 {
  constructor(config: gdir_realms_config = {}) { super(config); }
  protected override async fetchObject(): Promise<string> {
    return fs.readFileSync(path.join(TEST_DATA_DIR, "realms_v1.json"), "utf8");
  }
}

// ---------------------------------------------------------------------------
// regions/v1
// ---------------------------------------------------------------------------

describe("regions/v1", () => {
  const REGION_KEY = "tst-region-1";
  const client     = new MockRegions({ regionKey: REGION_KEY });
  // second region in same realm — needed for "other regions" tests
  const client2    = new MockRegions({ regionKey: "tst-region-2" });

  // --- document metadata ---------------------------------------------------

  it("getLastUpdatedTimestamp — undefined when not uploaded via tf_manager", async () => {
    expect(await client.getLastUpdatedTimestamp()).toBeUndefined();
  });

  // --- map-level ------------------------------------------------------------

  it("getRegions — map contains test region", async () => {
    const regions = await client.getRegions();
    expect(regions).toHaveProperty(REGION_KEY);
    expect(regions).not.toHaveProperty("last_updated_timestamp");
  });

  it("getRegionKeys — includes test region, excludes metadata", async () => {
    const keys = await client.getRegionKeys();
    expect(keys).toContain(REGION_KEY);
    expect(keys).not.toContain("last_updated_timestamp");
  });

  it("getRealms — returns distinct realm list", async () => {
    const realms = await client.getRealms();
    expect(realms).toContain("tst01");
  });

  // --- single region -------------------------------------------------------

  it("getRegion — returns region object", async () => {
    const region = await client.getRegion();
    expect(region).toHaveProperty("key", "T01");
    expect(region).toHaveProperty("realm", "tst01");
  });

  it("getRegionShortKey — returns T01", async () => {
    expect(await client.getRegionShortKey()).toBe("T01");
  });

  it("getRegionRealm — returns tst01", async () => {
    expect(await client.getRegionRealm()).toBe("tst01");
  });

  // --- realm grouping ------------------------------------------------------

  it("getRealmRegions — map contains tst-region-1", async () => {
    const regions = await client.getRealmRegions();
    expect(regions).toHaveProperty(REGION_KEY);
  });

  it("getRealmRegionKeys — includes tst-region-1", async () => {
    expect(await client.getRealmRegionKeys()).toContain(REGION_KEY);
  });

  it("getRealmOtherRegions — excludes tst-region-2 itself", async () => {
    const others = await client2.getRealmOtherRegions();
    expect(others).not.toHaveProperty("tst-region-2");
  });

  it("getRealmOtherRegionKeys — does not include own key", async () => {
    const keys = await client2.getRealmOtherRegionKeys();
    expect(keys).not.toContain("tst-region-2");
  });

  // --- network / CIDR ------------------------------------------------------

  it("getRegionNetwork — has public, internal, proxy", async () => {
    const net = await client.getRegionNetwork();
    expect(net).toHaveProperty("public");
    expect(net).toHaveProperty("internal");
    expect(net).toHaveProperty("proxy");
  });

  it("getRegionCidrPublic — returns array with CIDR entries", async () => {
    const cidrs = await client.getRegionCidrPublic();
    expect(cidrs.length).toBeGreaterThan(0);
    expect(cidrs[0]).toHaveProperty("cidr", "192.0.2.0/24");
    expect(cidrs[0].tags).toContain("public");
  });

  it("getRegionCidrInternal — returns array with CIDR entries", async () => {
    const cidrs = await client.getRegionCidrInternal();
    expect(cidrs.length).toBeGreaterThan(0);
  });

  it("getRegionCidrByTag — filters by tag correctly", async () => {
    const cidrs = await client.getRegionCidrByTag("public");
    expect(cidrs.length).toBeGreaterThan(0);
    cidrs.forEach(c => expect(c.tags).toContain("public"));
  });

  // --- proxy ---------------------------------------------------------------

  it("getRegionProxy — has url, ip, port, noproxy", async () => {
    const proxy = await client.getRegionProxy();
    expect(proxy).toHaveProperty("url");
    expect(proxy).toHaveProperty("ip");
    expect(proxy).toHaveProperty("port");
    expect(proxy).toHaveProperty("noproxy");
  });

  it("getRegionProxyUrl — correct URL", async () => {
    expect(await client.getRegionProxyUrl()).toBe("http://proxy.tst-region-1.example.com:8081");
  });

  it("getRegionProxyIp — correct IP", async () => {
    expect(await client.getRegionProxyIp()).toBe("10.1.1.1");
  });

  it("getRegionProxyPort — correct port", async () => {
    expect(await client.getRegionProxyPort()).toBe("8081");
  });

  it("getRegionProxyNoproxy — returns array", async () => {
    const list = await client.getRegionProxyNoproxy();
    expect(list).toContain("10.1.0.0/16");
    expect(list).toContain("*.tst-region-1.example.com");
  });

  it("getRegionProxyNoproxyString — comma-separated", async () => {
    const s = await client.getRegionProxyNoproxyString();
    expect(s).toContain(",");
    expect(s).toContain("10.1.0.0/16");
  });

  // --- vault ---------------------------------------------------------------

  it("getRegionVault — has ocid, crypto_endpoint, management_endpoint", async () => {
    const vault = await client.getRegionVault();
    expect(vault).toHaveProperty("ocid");
    expect(vault).toHaveProperty("crypto_endpoint");
    expect(vault).toHaveProperty("management_endpoint");
  });

  it("getRegionVaultOcid — starts with ocid1.vault", async () => {
    const ocid = await client.getRegionVaultOcid();
    expect(ocid).toMatch(/^ocid1\.vault\./);
  });

  it("getRegionVaultCryptoEndpoint — non-empty string", async () => {
    expect(await client.getRegionVaultCryptoEndpoint()).toBeTruthy();
  });

  it("getRegionVaultManagementEndpoint — non-empty string", async () => {
    expect(await client.getRegionVaultManagementEndpoint()).toBeTruthy();
  });

  // --- toolchain -----------------------------------------------------------

  it("getRegionGitHubRunner — has labels and image", async () => {
    const runner = await client.getRegionGitHubRunner();
    expect(runner).toHaveProperty("labels");
    expect(runner).toHaveProperty("image");
  });

  it("getRegionGitHubRunnerLabels — contains region and realm", async () => {
    const labels = await client.getRegionGitHubRunnerLabels();
    expect(labels).toContain(REGION_KEY);
    expect(labels).toContain("tst01");
    expect(labels).toContain("self-hosted");
  });

  it("getRegionGitHubRunnerImage — starts with ocid1.image", async () => {
    expect(await client.getRegionGitHubRunnerImage()).toMatch(/^ocid1\.image\./);
  });

  // --- observability -------------------------------------------------------

  it("getRegionObservability — has all three fields", async () => {
    const obs = await client.getRegionObservability();
    expect(obs).toHaveProperty("prometheus_scraping_cidr");
    expect(obs).toHaveProperty("loki_destination_cidr");
    expect(obs).toHaveProperty("loki_fqdn");
  });

  it("getRegionPromScrapingCidr — valid CIDR", async () => {
    expect(await client.getRegionPromScrapingCidr()).toBe("10.1.1.0/24");
  });

  it("getRegionLokiFqdn — contains region name", async () => {
    expect(await client.getRegionLokiFqdn()).toContain(REGION_KEY);
  });
});

// ---------------------------------------------------------------------------
// realms/v1
// ---------------------------------------------------------------------------

describe("realms/v1", () => {
  const client = new MockRealms({ realmKey: "oc1" });

  it("getLastUpdatedTimestamp — undefined when not uploaded via tf_manager", async () => {
    expect(await client.getLastUpdatedTimestamp()).toBeUndefined();
  });

  it("getRealms — map contains oc1 and oc19, excludes metadata", async () => {
    const realms = await client.getRealms();
    expect(realms).toHaveProperty("oc1");
    expect(realms).toHaveProperty("oc19");
    expect(realms).not.toHaveProperty("last_updated_timestamp");
  });

  it("getRealmKeys — includes oc1, oc19, tst01", async () => {
    const keys = await client.getRealmKeys();
    expect(keys).toContain("oc1");
    expect(keys).toContain("oc19");
    expect(keys).toContain("tst01");
  });

  it("getRealm — returns oc1 realm object", async () => {
    const realm = await client.getRealm();
    expect(realm).toHaveProperty("type", "public");
    expect(realm).toHaveProperty("name", "OCI Public");
  });

  it("getRealmType — returns public", async () => {
    expect(await client.getRealmType()).toBe("public");
  });

  it("getRealmName — returns OCI Public", async () => {
    expect(await client.getRealmName()).toBe("OCI Public");
  });

  it("getRealmDescription — non-empty string", async () => {
    expect(await client.getRealmDescription()).toBeTruthy();
  });

  it("getRealmGeoRegion — returns global", async () => {
    expect(await client.getRealmGeoRegion()).toBe("global");
  });

  it("getRealmApiDomain — returns oraclecloud.com", async () => {
    expect(await client.getRealmApiDomain()).toBe("oraclecloud.com");
  });

  it("sovereign realm oc19 — type is sovereign, domain is oraclecloud.eu", async () => {
    const c = new MockRealms({ realmKey: "oc19" });
    expect(await c.getRealmType()).toBe("sovereign");
    expect(await c.getRealmApiDomain()).toBe("oraclecloud.eu");
  });
});
