import { gdir } from "./gdir";
import { gdir_config } from "./config";
import { Realm, RealmsMap, RealmType } from "./types";

export interface gdir_realms_config extends gdir_config {
  /** Realm key for single-realm methods (e.g. "oc1", "tst01") */
  realmKey?: string;
}

const DEFAULT_REALMS_V1_OBJECT = process.env.GDIR_REALMS_OBJECT ?? "realms/v1";

/**
 * Realms v1 client — extends core with methods tied to the v1/realms data structure:
 * { [realmKey]: { geo-region, name, description, api_domain } }
 */
export class gdir_realms_v1 extends gdir {
  private cachedDoc: Record<string, unknown> | null = null;
  private readonly realmKey: string | undefined;

  constructor(config: gdir_realms_config = {}) {
    super(config, DEFAULT_REALMS_V1_OBJECT);
    this.realmKey = config.realmKey ?? process.env.REALM_KEY;
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

  /** Semver version of this data object */
  async getSchemaVersion(): Promise<string | undefined> {
    return this.getDoc().then(d => d["schema_version"] as string | undefined);
  }

  // ---------------------------------------------------------------------------
  // Realm map
  // ---------------------------------------------------------------------------

  /** All realms (v1 schema) — metadata fields excluded. */
  async getRealms(): Promise<RealmsMap> {
    const doc = await this.getDoc();
    const { last_updated_timestamp, schema_version, ...realms } = doc;
    return realms as RealmsMap;
  }

  /** All realm keys */
  async getRealmKeys(): Promise<string[]> {
    return Object.keys(await this.getRealms());
  }

  // ---------------------------------------------------------------------------
  // Single realm
  // ---------------------------------------------------------------------------

  private resolvedKey(): string {
    if (!this.realmKey) throw new Error("realmKey not set — pass via constructor config or REALM_KEY env var");
    return this.realmKey;
  }

  /** Full realm object for the configured realm key */
  async getRealm(): Promise<Realm> {
    const realms = await this.getRealms();
    const key = this.resolvedKey();
    const realm = realms[key];
    if (!realm) throw new Error(`Realm not found: ${key}`);
    return realm;
  }

  /** Short realm name, e.g. "OCI Public" */
  async getRealmName(): Promise<string> {
    return (await this.getRealm()).name;
  }

  /** Human-readable description */
  async getRealmDescription(): Promise<string> {
    return (await this.getRealm()).description;
  }

  /** Geographic region, e.g. "global", "eu" */
  async getRealmGeoRegion(): Promise<string> {
    return (await this.getRealm())["geo-region"];
  }

  /** Second-level domain for OCI API endpoints in this realm, e.g. "oraclecloud.com" */
  async getRealmApiDomain(): Promise<string> {
    return (await this.getRealm()).api_domain;
  }

  /** Deployment model: public | government | sovereign | drcc | alloy | airgapped */
  async getRealmType(): Promise<RealmType> {
    return (await this.getRealm()).type;
  }
}
