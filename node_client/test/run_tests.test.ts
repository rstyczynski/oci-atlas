/**
 * Jest tests — no OCI connectivity required.
 * Mock subclasses override fetchObject() to read local JSON test data.
 *
 * Run: npm run test:jest
 *      TEST_DATA_DIR=/path/to/tf_manager npm run test:jest
 */
import * as fs   from "fs";
import * as path from "path";

import { gdir_config }                              from "../src/config";
import { gdir_regions_v2 }                          from "../src/gdir_regions_v2";
import { gdir_tenancies_v1, gdir_tenancies_config } from "../src/gdir_tenancies_v1";
import { gdir_realms_v1, gdir_realms_config }       from "../src/gdir_realms_v1";

const TEST_DATA_DIR = process.env.TEST_DATA_DIR
  ?? path.resolve(__dirname, "../../tf_manager");

// ---------------------------------------------------------------------------
// Mock subclasses
// ---------------------------------------------------------------------------

class MockRegionsV2 extends gdir_regions_v2 {
  constructor(config: gdir_config = {}) { super(config); }
  protected override async fetchObject(): Promise<string> {
    return fs.readFileSync(path.join(TEST_DATA_DIR, "regions_v2.json"), "utf8");
  }
}

class MockTenancies extends gdir_tenancies_v1 {
  constructor(config: gdir_tenancies_config = {}) { super(config); }
  protected override async fetchObject(): Promise<string> {
    return fs.readFileSync(path.join(TEST_DATA_DIR, "tenancies_v1.json"), "utf8");
  }
}

class MockRealms extends gdir_realms_v1 {
  constructor(config: gdir_realms_config = {}) { super(config); }
  protected override async fetchObject(): Promise<string> {
    return fs.readFileSync(path.join(TEST_DATA_DIR, "realms_v1.json"), "utf8");
  }
}

// ---------------------------------------------------------------------------
// regions/v2
// ---------------------------------------------------------------------------

describe("regions/v2", () => {
  const REGION_KEY = "tst-region-1";
  const client     = new MockRegionsV2({ regionKey: REGION_KEY });
  const client2    = new MockRegionsV2({ regionKey: "tst-region-2" });

  // --- document metadata ---------------------------------------------------

  it("getLastUpdatedTimestamp — returns timestamp", async () => {
    expect(await client.getLastUpdatedTimestamp()).toBe("2026-02-25T12:00:00Z");
  });

  it("getSchemaVersion — returns 1.0.0", async () => {
    expect(await client.getSchemaVersion()).toBe("1.0.0");
  });

  // --- map-level ------------------------------------------------------------

  it("getRegions — map contains test region, excludes metadata", async () => {
    const regions = await client.getRegions();
    expect(regions).toHaveProperty(REGION_KEY);
    expect(regions).not.toHaveProperty("last_updated_timestamp");
    expect(regions).not.toHaveProperty("schema_version");
  });

  it("getRegionKeys — includes test region, excludes metadata", async () => {
    const keys = await client.getRegionKeys();
    expect(keys).toContain(REGION_KEY);
    expect(keys).not.toContain("last_updated_timestamp");
    expect(keys).not.toContain("schema_version");
  });

  it("getRealms — returns distinct realm list including tst01", async () => {
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

  it("getRegionCidrPublic — returns array with CIDR entries", async () => {
    const cidrs = await client.getRegionCidrPublic();
    expect(cidrs.length).toBeGreaterThan(0);
    expect(cidrs[0]).toHaveProperty("cidr", "192.0.2.0/24");
    expect(cidrs[0].tags).toContain("public");
  });

  it("getRegionCidrByTag — filters by tag correctly", async () => {
    const cidrs = await client.getRegionCidrByTag("public");
    expect(cidrs.length).toBeGreaterThan(0);
    cidrs.forEach(c => expect(c.tags).toContain("public"));
  });
});

// ---------------------------------------------------------------------------
// tenancies/v1
// ---------------------------------------------------------------------------

describe("tenancies/v1", () => {
  const TENANCY_KEY = "acme_prod";
  const REGION_KEY  = "eu-zurich-1";
  const client      = new MockTenancies({ tenancyKey: TENANCY_KEY, regionKey: REGION_KEY });

  // --- document metadata ---------------------------------------------------

  it("getLastUpdatedTimestamp — returns timestamp", async () => {
    expect(await client.getLastUpdatedTimestamp()).toBe("2026-02-25T12:00:00Z");
  });

  it("getSchemaVersion — returns 1.0.0", async () => {
    expect(await client.getSchemaVersion()).toBe("1.0.0");
  });

  // --- catalog -------------------------------------------------------------

  it("getTenancies — map contains acme_prod, excludes metadata", async () => {
    const tenancies = await client.getTenancies();
    expect(tenancies).toHaveProperty(TENANCY_KEY);
    expect(tenancies).not.toHaveProperty("last_updated_timestamp");
    expect(tenancies).not.toHaveProperty("schema_version");
  });

  it("getTenancyKeys — includes acme_prod", async () => {
    const keys = await client.getTenancyKeys();
    expect(keys).toContain(TENANCY_KEY);
  });

  it("getTenancy — returns tenancy object", async () => {
    const tenancy = await client.getTenancy();
    expect(tenancy).toHaveProperty("realm", "oc1");
    expect(tenancy).toHaveProperty("regions");
  });

  it("getTenancyRealm — returns oc1", async () => {
    expect(await client.getTenancyRealm()).toBe("oc1");
  });

  // --- per-region ----------------------------------------------------------

  it("getTenancyRegionKeys — includes eu-zurich-1", async () => {
    const keys = await client.getTenancyRegionKeys();
    expect(keys).toContain(REGION_KEY);
  });

  it("getTenancyRegion — returns region object", async () => {
    const region = await client.getTenancyRegion();
    expect(region).toHaveProperty("network");
    expect(region).toHaveProperty("security");
    expect(region).toHaveProperty("toolchain");
    expect(region).toHaveProperty("observability");
  });

  // --- network -------------------------------------------------------------

  it("getPrivateCidrs — returns array with CIDR entries", async () => {
    const cidrs = await client.getPrivateCidrs();
    expect(cidrs.length).toBeGreaterThan(0);
    expect(cidrs[0]).toHaveProperty("cidr", "10.0.0.0/16");
  });

  it("getPrivateCidrsByTag — filters by vcn tag", async () => {
    const cidrs = await client.getPrivateCidrsByTag("vcn");
    expect(cidrs.length).toBeGreaterThan(0);
    cidrs.forEach(c => expect(c.tags).toContain("vcn"));
  });

  it("getProxy — has url, ip, port, noproxy", async () => {
    const proxy = await client.getProxy();
    expect(proxy).toHaveProperty("url");
    expect(proxy).toHaveProperty("ip");
    expect(proxy).toHaveProperty("port");
    expect(proxy).toHaveProperty("noproxy");
  });

  it("getProxyUrl — correct URL", async () => {
    expect(await client.getProxyUrl()).toBe("http://proxy.eu-zurich-1.example.com:8080");
  });

  it("getProxyIp — correct IP", async () => {
    expect(await client.getProxyIp()).toBe("10.0.1.100");
  });

  it("getProxyPort — correct port", async () => {
    expect(await client.getProxyPort()).toBe("8080");
  });

  it("getProxyNoproxy — returns array", async () => {
    const list = await client.getProxyNoproxy();
    expect(list).toContain("10.0.0.0/8");
    expect(list).toContain("*.eu-zurich-1.oraclecloud.com");
  });

  it("getProxyNoproxyString — comma-separated", async () => {
    const s = await client.getProxyNoproxyString();
    expect(s).toContain(",");
    expect(s).toContain("10.0.0.0/8");
  });

  // --- security ------------------------------------------------------------

  it("getVault — has ocid, crypto_endpoint, management_endpoint", async () => {
    const vault = await client.getVault();
    expect(vault).toHaveProperty("ocid");
    expect(vault).toHaveProperty("crypto_endpoint");
    expect(vault).toHaveProperty("management_endpoint");
  });

  it("getVaultOcid — starts with ocid1.vault", async () => {
    expect(await client.getVaultOcid()).toMatch(/^ocid1\.vault\./);
  });

  it("getVaultCryptoEndpoint — non-empty string", async () => {
    expect(await client.getVaultCryptoEndpoint()).toBeTruthy();
  });

  it("getVaultManagementEndpoint — non-empty string", async () => {
    expect(await client.getVaultManagementEndpoint()).toBeTruthy();
  });

  // --- toolchain -----------------------------------------------------------

  it("getGitHubRunner — has labels and image", async () => {
    const runner = await client.getGitHubRunner();
    expect(runner).toHaveProperty("labels");
    expect(runner).toHaveProperty("image");
  });

  it("getGitHubRunnerLabels — contains region and realm", async () => {
    const labels = await client.getGitHubRunnerLabels();
    expect(labels).toContain(REGION_KEY);
    expect(labels).toContain("oc1");
    expect(labels).toContain("self-hosted");
  });

  it("getGitHubRunnerImage — starts with ocid1.image", async () => {
    expect(await client.getGitHubRunnerImage()).toMatch(/^ocid1\.image\./);
  });

  // --- observability -------------------------------------------------------

  it("getObservability — has all three fields", async () => {
    const obs = await client.getObservability();
    expect(obs).toHaveProperty("prometheus_scraping_cidr");
    expect(obs).toHaveProperty("loki_destination_cidr");
    expect(obs).toHaveProperty("loki_fqdn");
  });

  it("getPromScrapingCidr — valid CIDR", async () => {
    expect(await client.getPromScrapingCidr()).toBe("10.0.1.0/24");
  });

  it("getLokiFqdn — contains region name", async () => {
    expect(await client.getLokiFqdn()).toContain(REGION_KEY);
  });
});

// ---------------------------------------------------------------------------
// realms/v1
// ---------------------------------------------------------------------------

describe("realms/v1", () => {
  const client = new MockRealms({ realmKey: "oc1" });

  it("getLastUpdatedTimestamp — returns timestamp", async () => {
    expect(await client.getLastUpdatedTimestamp()).toBe("2026-02-25T12:00:00Z");
  });

  it("getSchemaVersion — returns 1.0.0", async () => {
    expect(await client.getSchemaVersion()).toBe("1.0.0");
  });

  it("getRealms — map contains oc1 and oc19, excludes metadata", async () => {
    const realms = await client.getRealms();
    expect(realms).toHaveProperty("oc1");
    expect(realms).toHaveProperty("oc19");
    expect(realms).not.toHaveProperty("last_updated_timestamp");
    expect(realms).not.toHaveProperty("schema_version");
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
