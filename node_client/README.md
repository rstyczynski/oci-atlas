# node_client

Node.js/TypeScript client for the global directory. Reads `regions/v1` from OCI Object Storage via the OCI TypeScript SDK.

## Prerequisites

- Node.js 18+
- `~/.oci/config`

## Setup

```bash
npm install
```

## ENV vars

| Var | Default | Description |
|-----|---------|-------------|
| `REGION_KEY` | active OCI region | Region key for single-region methods |
| `GDIR_BUCKET` | `gdir_info` | Bucket name |
| `GDIR_OBJECT` | `regions/v1` | Object name |

## Schema versioning

The client is split into two layers:

- **`gdir`** (core) — auth, region discovery, raw object fetch. Schema-independent.
- **`gdir_regions_v1`** (DAL) — parses and exposes data according to the `regions/v1` schema. Add a new DAL class (e.g. `gdir_regions_v2`) when the schema changes.

Consumers always import the DAL class. Core is an implementation detail.

## API

`regionKey`, `bucketName`, `objectName` are module properties — the caller only provides `regionKey` (optional).

```typescript
import { gdir_regions_v1 } from "./src";

// regionKey from REGION_KEY env or active OCI region
const client = new gdir_regions_v1();

// explicit region
const client = new gdir_regions_v1({ regionKey: "eu-zurich-1" });

await client.getRegions();                    // all regions
await client.getRegionKeys();                 // all keys
await client.getRealms();                     // distinct realms
await client.getRegion();                     // one region object
await client.getRegionShortKey();             // short code e.g. ZRH
await client.getRegionRealm();                // realm
await client.getRealmRegions();               // regions in same realm
await client.getRealmRegionKeys();            // keys in same realm
await client.getRealmOtherRegions();          // same-realm peers (excl. self)
await client.getRealmOtherRegionKeys();       // keys of same-realm peers
await client.getRegionNetwork();              // full network object
await client.getRegionCidrPublic();           // public CIDR entries
await client.getRegionCidrInternal();         // internal CIDR entries
await client.getRegionCidrByTag("OCI");       // CIDRs filtered by tag
await client.getRegionProxy();                // proxy object
await client.getRegionProxyUrl();             // proxy URL
await client.getRegionProxyIp();              // proxy IP
await client.getRegionProxyPort();            // proxy port
await client.getRegionProxyNoproxy();         // no-proxy list
await client.getRegionProxyNoproxyString();   // no-proxy as NO_PROXY string
await client.getRegionSecurity();             // full security object
await client.getRegionVault();                // vault object
await client.getRegionVaultOcid();            // vault OCID
await client.getRegionToolchain();            // full toolchain object
await client.getRegionGitHub();               // GitHub object
await client.getRegionGitHubRunnerLabels();   // runner labels
await client.getRegionGitHubRunnerImage();    // runner image OCID
await client.getRegionObservability();        // observability object
await client.getRegionPromScrapingCidr();     // Prometheus scraping CIDR
await client.getRegionLokiDestCidr();         // Loki destination CIDR
await client.getRegionLokiFqdn();             // Loki FQDN
```

## Examples

```bash
npm run example:all
REGION_KEY=eu-zurich-1 npm run example:region
```
