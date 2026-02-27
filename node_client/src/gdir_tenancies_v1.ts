import { gdir } from "./gdir";
import * as identity from "oci-identity";
import * as common from "oci-common";
import { gdir_config } from "./config";
import {
  CidrEntry, GitHub, GitHubRunner, Observability, Proxy,
  Security, Tenancy, TenanciesMap, TenancyNetwork, TenancyRegion,
  Toolchain, Vault,
} from "./types";

export interface gdir_tenancies_config extends gdir_config {
  /** Tenancy key (e.g. "acme_prod"); optional when only getTenancies/getTenancyKeys are needed */
  tenancyKey?: string;
}

/**
 * Tenancies v1 client — extends core with methods tied to the v1/tenancies data structure:
 * { [tenancyKey]: { realm, regions: { [regionKey]: { network, security, toolchain, observability } } } }
 */
const DEFAULT_TENANCIES_V1_OBJECT = process.env.GDIR_TENANCIES_V1_OBJECT ?? "tenancies/v1";

export class gdir_tenancies_v1 extends gdir {
  private cachedDoc: Record<string, unknown> | null = null;
  private readonly explicitTenancyKey: string | undefined;
  private cachedTenancyKey: string | null = null;

  constructor(config: gdir_tenancies_config = {}) {
    super(config, DEFAULT_TENANCIES_V1_OBJECT);
    this.explicitTenancyKey = config.tenancyKey ?? process.env.TENANCY_KEY;
  }

  private async getDoc(): Promise<Record<string, unknown>> {
    if (!this.cachedDoc) this.cachedDoc = JSON.parse(await this.fetchObject());
    return this.cachedDoc!;
  }

  private async resolveTenancyKey(): Promise<string> {
    // Explicit override wins
    if (this.explicitTenancyKey) return this.explicitTenancyKey;
    if (this.cachedTenancyKey) return this.cachedTenancyKey;

    // Discover tenancy OCID from namespace metadata (current connection)
    const namespace = await this.getNamespace();
    // getNamespaceMetadata returns default S3 compartment OCID which is the tenancy OCID
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    const nsMeta: any = await (this as any).client.getNamespaceMetadata({ namespaceName: namespace });
    const tenancyOcid: string | undefined =
      nsMeta?.namespaceMetadata?.defaultS3CompartmentId ?? nsMeta?.defaultS3CompartmentId;
    if (!tenancyOcid) {
      throw new Error("TENANCY_KEY not set and could not derive tenancy OCID from getNamespaceMetadata; set TENANCY_KEY explicitly");
    }

    // Use IAM to get tenancy name for this OCID
    const provider = new common.ConfigFileAuthenticationDetailsProvider(
      (this as any).ociConfig?.ociConfigFile,
      (this as any).ociConfig?.ociProfile
    );
    const iamClient = new identity.IdentityClient({ authenticationDetailsProvider: provider });
    const tenancy = await iamClient.getTenancy({ tenancyId: tenancyOcid });
    const derivedKey = tenancy?.tenancy?.name;
    if (!derivedKey) {
      throw new Error(`TENANCY_KEY not set and failed to derive tenancy key from IAM tenancy name for OCID ${tenancyOcid}`);
    }

    // Ensure derived key exists in tenancies map
    const tenancies = await this.getTenancies();
    if (!Object.prototype.hasOwnProperty.call(tenancies, derivedKey)) {
      throw new Error(
        `Derived tenancy key '${derivedKey}' (from IAM) is not present in tenancies/v1 data; either add it to the dataset or set TENANCY_KEY explicitly`
      );
    }

    this.cachedTenancyKey = derivedKey;
    return derivedKey;
  }

  // ---------------------------------------------------------------------------
  // Document metadata
  // ---------------------------------------------------------------------------

  /** ISO 8601 timestamp injected by tf_manager at upload time */
  async getLastUpdatedTimestamp(): Promise<string | undefined> {
    return this.getDoc().then(d => d["last_updated_timestamp"] as string | undefined);
  }

  /** Semver version of this data object */
  async getSchemaVersion(): Promise<string | undefined> {
    return this.getDoc().then(d => d["schema_version"] as string | undefined);
  }

  // ---------------------------------------------------------------------------
  // Tenancy catalog
  // ---------------------------------------------------------------------------

  /** All tenancies — metadata fields excluded */
  async getTenancies(): Promise<TenanciesMap> {
    const doc = await this.getDoc();
    const { last_updated_timestamp, schema_version, ...tenancies } = doc;
    return tenancies as TenanciesMap;
  }

  /** All tenancy keys */
  async getTenancyKeys(): Promise<string[]> {
    return Object.keys(await this.getTenancies());
  }

  /** Full tenancy object for the configured tenancy key */
  async getTenancy(tenancyKey?: string): Promise<Tenancy> {
    const key = tenancyKey ?? (await this.resolveTenancyKey());
    const tenancies = await this.getTenancies();
    const tenancy = tenancies[key];
    if (!tenancy) throw new Error(`Tenancy not found: ${key}`);
    return tenancy;
  }

  /** Realm of the configured tenancy */
  async getTenancyRealm(): Promise<string> {
    return (await this.getTenancy()).realm;
  }

  // ---------------------------------------------------------------------------
  // Per-region
  // ---------------------------------------------------------------------------

  /** Region keys for the configured tenancy */
  async getTenancyRegionKeys(): Promise<string[]> {
    return Object.keys((await this.getTenancy()).regions);
  }

  /** Region object for configured tenancy + resolved region key */
  async getTenancyRegion(): Promise<TenancyRegion> {
    const tenancy = await this.getTenancy();
    const regionKey = await this.resolveRegionKey();
    const region = tenancy.regions[regionKey];
    if (!region) {
      const tenancyKey = await this.resolveTenancyKey();
      throw new Error(`Region '${regionKey}' not found in tenancy '${tenancyKey}'`);
    }
    return region;
  }

  // ---------------------------------------------------------------------------
  // Network
  // ---------------------------------------------------------------------------

  /** Full network object */
  async getNetwork(): Promise<TenancyNetwork> {
    return (await this.getTenancyRegion()).network;
  }

  /** Private CIDR entries */
  async getPrivateCidrs(): Promise<CidrEntry[]> {
    return (await this.getNetwork()).private;
  }

  /** Private CIDR entries matching a given tag */
  async getPrivateCidrsByTag(tag: string): Promise<CidrEntry[]> {
    return (await this.getPrivateCidrs()).filter(e => e.tags.includes(tag));
  }

  /** Proxy object */
  async getProxy(): Promise<Proxy> {
    return (await this.getNetwork()).proxy;
  }

  /** Proxy URL */
  async getProxyUrl(): Promise<string> {
    return (await this.getProxy()).url;
  }

  /** Proxy IP */
  async getProxyIp(): Promise<string> {
    return (await this.getProxy()).ip;
  }

  /** Proxy port */
  async getProxyPort(): Promise<string> {
    return (await this.getProxy()).port;
  }

  /** No-proxy list */
  async getProxyNoproxy(): Promise<string[]> {
    return (await this.getProxy()).noproxy;
  }

  /** No-proxy list as a comma-separated string (ready for NO_PROXY env var) */
  async getProxyNoproxyString(): Promise<string> {
    return (await this.getProxyNoproxy()).join(",");
  }

  // ---------------------------------------------------------------------------
  // Security
  // ---------------------------------------------------------------------------

  /** Full security object */
  async getSecurity(): Promise<Security> {
    return (await this.getTenancyRegion()).security;
  }

  /** Full vault object */
  async getVault(): Promise<Vault> {
    return (await this.getSecurity()).vault;
  }

  /** Vault OCID */
  async getVaultOcid(): Promise<string> {
    return (await this.getVault()).ocid;
  }

  /** Vault cryptographic operations endpoint */
  async getVaultCryptoEndpoint(): Promise<string> {
    return (await this.getVault()).crypto_endpoint;
  }

  /** Vault management endpoint */
  async getVaultManagementEndpoint(): Promise<string> {
    return (await this.getVault()).management_endpoint;
  }

  // ---------------------------------------------------------------------------
  // Toolchain
  // ---------------------------------------------------------------------------

  /** Full toolchain object */
  async getToolchain(): Promise<Toolchain> {
    return (await this.getTenancyRegion()).toolchain;
  }

  /** Full GitHub object */
  async getGitHub(): Promise<GitHub> {
    return (await this.getToolchain()).github;
  }

  /** Full GitHub runner object */
  async getGitHubRunner(): Promise<GitHubRunner> {
    return (await this.getGitHub()).runner;
  }

  /** GitHub Actions runner labels */
  async getGitHubRunnerLabels(): Promise<string[]> {
    return (await this.getGitHubRunner()).labels;
  }

  /** Compute image OCID used for GitHub runner instances */
  async getGitHubRunnerImage(): Promise<string> {
    return (await this.getGitHubRunner()).image;
  }

  // ---------------------------------------------------------------------------
  // Observability
  // ---------------------------------------------------------------------------

  /** Full observability object */
  async getObservability(): Promise<Observability> {
    return (await this.getTenancyRegion()).observability;
  }

  /** CIDR allowed to scrape Prometheus */
  async getPromScrapingCidr(): Promise<string> {
    return (await this.getObservability()).prometheus_scraping_cidr;
  }

  /** CIDR of the Loki destination */
  async getLokiDestCidr(): Promise<string> {
    return (await this.getObservability()).loki_destination_cidr;
  }

  /** FQDN of the Loki endpoint */
  async getLokiFqdn(): Promise<string> {
    return (await this.getObservability()).loki_fqdn;
  }
}
