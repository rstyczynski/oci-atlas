import { gdir } from "./gdir";
import { gdir_config } from "./config";
import { CidrEntry, GitHub, GitHubRunner, Network, Observability, Proxy, Region, RegionsMap, Security, Toolchain, Vault } from "./types";

/**
 * Regions v1 client — extends core with methods tied to the v1/regions data structure:
 * { [regionKey]: { key, realm, network: { public, internal, proxy }, security: { vault }, toolchain: { github }, observability } }
 */
const DEFAULT_REGIONS_V1_OBJECT = process.env.GDIR_REGIONS_OBJECT ?? "regions/v1";

export class gdir_regions_v1 extends gdir {
  private cachedDoc: Record<string, unknown> | null = null;

  constructor(config: gdir_config = {}) {
    super(config, DEFAULT_REGIONS_V1_OBJECT);
  }

  private async getDoc(): Promise<Record<string, unknown>> {
    if (!this.cachedDoc) this.cachedDoc = JSON.parse(await this.fetchObject());
    return this.cachedDoc!;
  }

  // ---------------------------------------------------------------------------
  // Document metadata
  // ---------------------------------------------------------------------------

  /** ISO 8601 timestamp injected by tf_manager at upload time */
  async getLastUpdatedTimestamp(): Promise<string | undefined> {
    return this.getDoc().then(d => d["last_updated_timestamp"] as string | undefined);
  }

  // ---------------------------------------------------------------------------
  // Region map
  // ---------------------------------------------------------------------------

  /** All regions (v1 schema) — metadata fields excluded. */
  async getRegions(): Promise<RegionsMap> {
    const doc = await this.getDoc();
    const { last_updated_timestamp, ...regions } = doc;
    return regions as RegionsMap;
  }

  /** List of all region keys */
  async getRegionKeys(): Promise<string[]> {
    return Object.keys(await this.getRegions());
  }

  // ---------------------------------------------------------------------------
  // Single region
  // ---------------------------------------------------------------------------

  /** One region object — uses explicit regionKey or bucket OCID auto-discovery */
  async getRegion(): Promise<Region> {
    const key = await this.resolveRegionKey();
    const regions = await this.getRegions();
    const region = regions[key];
    if (!region) throw new Error(`Region '${key}' not found in v1 data`);
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
    return [...new Set(Object.values(regions).map(r => (r as Region).realm))];
  }

  /** All regions in the same realm as the configured region */
  async getRealmRegions(): Promise<RegionsMap> {
    const realm = await this.getRegionRealm();
    const regions = await this.getRegions();
    return Object.fromEntries(
      Object.entries(regions).filter(([, r]) => (r as Region).realm === realm)
    );
  }

  /** Keys of regions in the same realm */
  async getRealmRegionKeys(): Promise<string[]> {
    return Object.keys(await this.getRealmRegions());
  }

  /** All regions in the same realm, excluding the active region */
  async getRealmOtherRegions(): Promise<RegionsMap> {
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

  /** Full network object (CIDR + proxy) */
  async getRegionNetwork(): Promise<Network> {
    return (await this.getRegion()).network;
  }

  /** Public CIDR entries */
  async getRegionCidrPublic(): Promise<CidrEntry[]> {
    return (await this.getRegionNetwork()).public;
  }

  /** Internal CIDR entries */
  async getRegionCidrInternal(): Promise<CidrEntry[]> {
    return (await this.getRegionNetwork()).internal;
  }

  /** All CIDR entries (public + internal) matching a given tag (e.g. "OCI", "OSN", "vcn") */
  async getRegionCidrByTag(tag: string): Promise<CidrEntry[]> {
    const net = await this.getRegionNetwork();
    return [...net.public, ...net.internal].filter(e => e.tags.includes(tag));
  }

  // ---------------------------------------------------------------------------
  // Proxy
  // ---------------------------------------------------------------------------

  /** Proxy object for the region */
  async getRegionProxy(): Promise<Proxy> {
    return (await this.getRegionNetwork()).proxy;
  }

  /** Proxy URL */
  async getRegionProxyUrl(): Promise<string> {
    return (await this.getRegionProxy()).url;
  }

  /** Proxy IP */
  async getRegionProxyIp(): Promise<string> {
    return (await this.getRegionProxy()).ip;
  }

  /** Proxy port */
  async getRegionProxyPort(): Promise<string> {
    return (await this.getRegionProxy()).port;
  }

  /** No-proxy list */
  async getRegionProxyNoproxy(): Promise<string[]> {
    return (await this.getRegionProxy()).noproxy;
  }

  /** No-proxy list as a comma-separated string (ready for NO_PROXY env var) */
  async getRegionProxyNoproxyString(): Promise<string> {
    return (await this.getRegionProxyNoproxy()).join(",");
  }

  // ---------------------------------------------------------------------------
  // Vault
  // ---------------------------------------------------------------------------

  /** Full security object */
  async getRegionSecurity(): Promise<Security> {
    return (await this.getRegion()).security;
  }

  /** Full vault object */
  async getRegionVault(): Promise<Vault> {
    return (await this.getRegionSecurity()).vault;
  }

  /** Vault OCID */
  async getRegionVaultOcid(): Promise<string> {
    return (await this.getRegionVault()).ocid;
  }

  /** Vault cryptographic operations endpoint */
  async getRegionVaultCryptoEndpoint(): Promise<string> {
    return (await this.getRegionVault()).crypto_endpoint;
  }

  /** Vault management endpoint */
  async getRegionVaultManagementEndpoint(): Promise<string> {
    return (await this.getRegionVault()).management_endpoint;
  }

  // ---------------------------------------------------------------------------
  // GitHub
  // ---------------------------------------------------------------------------

  /** Full GitHub object */
  async getRegionToolchain(): Promise<Toolchain> {
    return (await this.getRegion()).toolchain;
  }

  /** Full GitHub object */
  async getRegionGitHub(): Promise<GitHub> {
    return (await this.getRegionToolchain()).github;
  }

  /** Full GitHub runner object */
  async getRegionGitHubRunner(): Promise<GitHubRunner> {
    return (await this.getRegionGitHub()).runner;
  }

  /** GitHub Actions runner labels for this region */
  async getRegionGitHubRunnerLabels(): Promise<string[]> {
    return (await this.getRegionGitHubRunner()).labels;
  }

  /** Compute image OCID used for GitHub runner instances */
  async getRegionGitHubRunnerImage(): Promise<string> {
    return (await this.getRegionGitHubRunner()).image;
  }

  // ---------------------------------------------------------------------------
  // Observability
  // ---------------------------------------------------------------------------

  /** Full observability object */
  async getRegionObservability(): Promise<Observability> {
    return (await this.getRegion()).observability;
  }

  /** CIDR allowed to scrape Prometheus */
  async getRegionPromScrapingCidr(): Promise<string> {
    return (await this.getRegionObservability()).prometheus_scraping_cidr;
  }

  /** CIDR of the Loki destination */
  async getRegionLokiDestCidr(): Promise<string> {
    return (await this.getRegionObservability()).loki_destination_cidr;
  }

  /** FQDN of the Loki endpoint */
  async getRegionLokiFqdn(): Promise<string> {
    return (await this.getRegionObservability()).loki_fqdn;
  }

}
