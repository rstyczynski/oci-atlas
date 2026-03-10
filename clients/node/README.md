# clients/node — Node/TypeScript client

Node.js/TypeScript client for OCI Atlas global directory data in Object Storage.

## Architecture

- `gdir_regions_v2`: region DAL (`regions/v2`).
- `gdir_tenancies_v1`: tenancy DAL (`tenancies/v1`).
- `gdir_realms_v1`: realm DAL (`realms/v1`).

All DALs extend the core `gdir` class, which handles:

- OCI auth (config file or instance principal).
- Namespace lookup and bucket/object fetch.
- Region auto-discovery from bucket OCID.

## Prerequisites

- Node.js 18+
- OCI credentials (`~/.oci/config` or instance principal)

## Example usage

```bash
# Regions
cd clients/node
npm install
npm run example:region
REGION_KEY=eu-zurich-1 npm run example:region
npm run example:regions

# Tenancies (tenancies/v1)
npm run example:tenancy
TENANCY_KEY=demo_corp REGION_KEY=tst-region-1 npm run example:tenancy

# Realms
npm run example:realms
REALM_KEY=oc1 npm run example:realm
```

## Arguments

### Environment variables

| Var | Default | Description |
| --- | --- | --- |
| `REGION_KEY` | auto-discovered from bucket OCID | Region key override |
| `TENANCY_KEY` | auto-discovered from tenancy context | Tenancy key override |
| `REALM_KEY` | unset | Realm key for single-realm calls |

### SDK level

| Var | Default | Description |
| --- | --- | --- |
| `GDIR_BUCKET` | `gdir_info` | Object Storage bucket name |
| `GDIR_REGIONS_V2_OBJECT` | `regions/v2` | Regions object path override |
| `GDIR_TENANCIES_V1_OBJECT` | `tenancies/v1` | Tenancies object path override |
| `GDIR_REALMS_OBJECT` | `realms/v1` | Realms object path override |
| `GDIR_DATA_DIR` | unset | Offline JSON fixture directory (for tests/examples); if set, object content is read from local files instead of OCI |

## Constructor configs (SDK level)

Programmatic configuration objects passed to the Node/TypeScript constructors instead of using environment variables:

- `gdir_config` (used by `gdir_regions_v2`):
  - `regionKey` — region key override (defaults to derived from bucket OCID).
  - `bucketName` — Object Storage bucket (defaults to `GDIR_BUCKET` or `gdir_info`).
  - `ociConfigFile`, `ociProfile` — optional OCI config location/profile.
- `gdir_tenancies_config` (extends `gdir_config`):
  - `tenancyKey` — tenancy key override (defaults to `TENANCY_KEY` or IAM discovery).
- `gdir_realms_config` (extends `gdir_config`):
  - `realmKey` — realm key override (defaults to `REALM_KEY`).

## Functions

Data access function are grouped by return types:

- **Scalars** — single values (string/number).
- **Lists** — arrays of scalars (e.g. `string[]`).
- **Objects / maps** — structured JSON-like objects.

### Regions (`gdir_regions_v2`)

- **Scalars**
  - `getSchemaVersion()` → schema version string.
  - `getLastUpdatedTimestamp()` → ISO 8601 timestamp.
  - `getRegionShortKey()` → short region key (e.g. `ZRH`).
  - `getRegionRealm()` → realm key (e.g. `oc1`, `tst01`).
- **Lists**
  - `getRegionKeys()` → region keys (`string[]`).
  - `getRealms()` → distinct realm keys (`string[]`).
  - `getRegionCidrPublic()` → public CIDR list (`string[]`).
  - `getRegionCidrByTag(tag)` → public CIDRs filtered by tag (`string[]`).
- **Objects / maps**
  - `getRegions()` → full regions map (without metadata).
  - `getRegion()` → selected region object.
  - `getRealmRegions()` → regions in the same realm as current region.
  - `getRealmRegionKeys()` → keys of regions in the same realm.
  - `getRealmOtherRegions()` → same-realm regions except current.
  - `getRealmOtherRegionKeys()` → keys of same-realm regions except current.

### Tenancies (`gdir_tenancies_v1`)

- **Scalars**
  - `getSchemaVersion()`
  - `getLastUpdatedTimestamp()`
  - `getTenancyRealm()` → tenancy realm.
  - `getProxyUrl()`, `getProxyIp()`, `getProxyPort()`
  - `getProxyNoproxyString()` → comma-separated `NO_PROXY` value.
  - `getVaultOcid()`, `getVaultCryptoEndpoint()`, `getVaultManagementEndpoint()`
  - `getGitHubRunnerImage()`
  - `getPromScrapingCidr()`, `getLokiDestCidr()`, `getLokiFqdn()`
- **Lists**
  - `getTenancyKeys()` → tenancy keys.
  - `getTenancyRegionKeys()` → region keys for tenancy.
  - `getPrivateCidrs()` → private CIDR list (`string[]`).
  - `getPrivateCidrsByTag(tag)` → private CIDRs by tag (`string[]`).
  - `getProxyNoproxy()` → no-proxy entries (`string[]`).
  - `getGitHubRunnerLabels()` → GitHub Actions runner labels (`string[]`).
- **Objects / maps**
  - `getTenancies()` → full tenancies map (without metadata).
  - `getTenancy(tenancyKey?)` → selected tenancy object.
  - `getTenancyRegion()` → selected tenancy region object.
  - `getNetwork()` → region network section.
  - `getProxy()` → proxy section.
  - `getSecurity()`, `getVault()`
  - `getToolchain()`, `getGitHub()`, `getGitHubRunner()`
  - `getObservability()`

### Realms (`gdir_realms_v1`)

- **Scalars**
  - `getSchemaVersion()`
  - `getLastUpdatedTimestamp()`
  - `getRealmType()`
  - `getRealmName()`
  - `getRealmDescription()`
  - `getRealmGeoRegion()`
  - `getRealmApiDomain()`
- **Lists**
  - `getRealmKeys()` → all realm keys (metadata keys excluded).
- **Objects / maps**
  - `getRealms()` → full realms map (without metadata).
  - `getRealm()` → selected realm object (`realmKey` / `REALM_KEY`).
