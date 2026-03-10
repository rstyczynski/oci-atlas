import { gdir } from "./gdir";
import { gdir_config } from "./config";
import { CidrEntry, RegionV2, RegionsV2Map } from "./types";

/**
 * Regions v2 client — extends core with methods tied to the v2/regions data structure:
 * { [regionKey]: { key, realm, network: { public } } }
 * Tenancy-specific attributes (proxy, vault, toolchain, observability) are in gdir_tenancies_v1.
 */
const DEFAULT_REGIONS_V2_OBJECT = process.env.GDIR_REGIONS_V2_OBJECT ?? "regions/v2";

export class gdir_regions_v2 extends gdir {
  private cachedDoc: Record<string, unknown> | null = null;

  constructor(config: gdir_config = {}) {
    super(config, DEFAULT_REGIONS_V2_OBJECT);
  }

  private async getDoc(): Promise<Record<string, unknown>> {
    if (!this.cachedDoc) this.cachedDoc = JSON.parse(await this.fetchObject());
    return this.cachedDoc!;
  }

  // ---------------------------------------------------------------------------
  // Document metadata
  // ---------------------------------------------------------------------------

  /** Semver version of this data object */
  async getSchemaVersion(): Promise<string | undefined> {
    return this.getDoc().then(d => d["schema_version"] as string | undefined);
  }

  // ---------------------------------------------------------------------------
  // Region map
  // ---------------------------------------------------------------------------

  /** All regions (v2 schema) — metadata fields excluded. */
  async getRegions(): Promise<RegionsV2Map> {
    const doc = await this.getDoc();
    const { schema_version, ...regions } = doc;
    return regions as RegionsV2Map;
  }

  /** List of all region keys */
  async getRegionKeys(): Promise<string[]> {
    return Object.keys(await this.getRegions());
  }

  // ---------------------------------------------------------------------------
  // Single region
  // ---------------------------------------------------------------------------

  /** One region object — uses explicit regionKey or bucket OCID auto-discovery */
  async getRegion(): Promise<RegionV2> {
    const key = await this.resolveRegionKey();
    const regions = await this.getRegions();
    const region = regions[key];
    if (!region) throw new Error(`Region '${key}' not found in v2 data`);
    return region;
  }

  // ---------------------------------------------------------------------------
  // Short key
  // ---------------------------------------------------------------------------

  /** Short region code (e.g. ZRH, FRA) */
  async getRegionShortKey(): Promise<string> {
    return (await this.getRegion()).key;
  }

  // ---------------------------------------------------------------------------
  // Realm
  // ---------------------------------------------------------------------------

  /** Realm for the region */
  async getRegionRealm(): Promise<string> {
    return (await this.getRegion()).realm;
  }

  /** All distinct realms */
  async getRealms(): Promise<string[]> {
    const regions = await this.getRegions();
    return [...new Set(Object.values(regions).map(r => (r as RegionV2).realm))];
  }

  /** All regions in the same realm as the configured region */
  async getRealmRegions(): Promise<RegionsV2Map> {
    const realm = await this.getRegionRealm();
    const regions = await this.getRegions();
    return Object.fromEntries(
      Object.entries(regions).filter(([, r]) => (r as RegionV2).realm === realm)
    );
  }

  /** Keys of regions in the same realm */
  async getRealmRegionKeys(): Promise<string[]> {
    return Object.keys(await this.getRealmRegions());
  }

  /** All regions in the same realm, excluding the active region */
  async getRealmOtherRegions(): Promise<RegionsV2Map> {
    const key = await this.resolveRegionKey();
    const realmRegions = await this.getRealmRegions();
    const { [key]: _excluded, ...others } = realmRegions;
    return others;
  }

  /** Keys of other regions in the same realm */
  async getRealmOtherRegionKeys(): Promise<string[]> {
    return Object.keys(await this.getRealmOtherRegions());
  }

  // ---------------------------------------------------------------------------
  // CIDR
  // ---------------------------------------------------------------------------

  /** Public CIDR entries (CIDR strings, aligned with CLI/TF) */
  async getRegionCidrPublic(): Promise<string[]> {
    return (await this.getRegion()).network.public.map((e: CidrEntry) => e.cidr);
  }

  /** Public CIDR entries matching a given tag (CIDR strings) */
  async getRegionCidrByTag(tag: string): Promise<string[]> {
    return (await this.getRegion()).network.public
      .filter((e: CidrEntry) => e.tags.includes(tag))
      .map(e => e.cidr);
  }
}
