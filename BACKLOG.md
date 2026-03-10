# OCI Atlas - Global Directory

version: 1

Global Directory is a centralized catalog system for Oracle Cloud Infrastructure (OCI) metadata — region attributes (network, proxy, vault, toolchain, observability) and realm information. It stores JSON data in OCI Object Storage with schema validation, versioning by domain, and provides typed client libraries for Node.js, CLI (Bash), and Terraform to read the data.

## Backlog

Project aim is to deliver all the features listed in a below Backlog. Backlog Items selected for implementation are added to iterations detailed in `PLAN.md`. Full list of Backlog Items presents general direction and aim for this project.

### GD-1. Build foundation data model

The region properties are strictly related to a tenancy for private attributes, and to physical region for physical attributes as e.g. public CIDRs. Both are associated to realm. Single region belongs to a single realm. The same with Tenancy. The tenancy may be subscribed to multiple realms.

                    +----------------------+
                    |         REALM        |
                    +----------------------+
                      1 |               | 1
                        |               |
                        v               v
                 +------------+   +------------+
                 |   REGION   |   |  TENANCY   |
                 +------------+   +------------+
                      ^                 ^
                      |                 |
                      +------- M:N -----+
                          subscription

Currently realm_v1 describes a realm, and region_v1 as is described combined single tenancy from region point of view.

The goal for a data model is to simplify runtime side scripts and programs' in environment discovery under defined OCI security context a.k.a connection.

This task defines data model for realm, region, and tenancy to be used by clients to discover for current region:
1. proxy URL
2. proxy IP, port
3. prometheus attributes for current region
4. github attributes for current region

Note that region_v1 data set combines real regions and tenancies, what should be divided into proper data domains.

Product of this task is to produce data model v2 reflecting tuple: realm, region, tenancy. It's just a model w/o provisioning add w/o DAL.

### GD-1-fix1. Remove `realm` attribute from tenancies json data file

### GD-2. Establish versioning strategy for data and access layer

Data and code is tracked by a [semantic versioning](https://semver.org) e.g. 1.5.12

MAJOR - indicating breaking change. Previous version cannot use current version data or logic
MINOR - indicating new feature. Previous version may use current version w/o access to new features
PATCH - bug fix adjusting data / code to state required by given MAJOR.MINOR

Areas for analysis:

1.Object Storage

* clients in given version have access to their data in the bucket
* MAJOR versions are under ${data}/${MAJOR} directory
* MINOR are indicated by filename i.e. ${data}/${MAJOR}/${data}-${MAJOR}.${MINOR}.json. Latest MINOR is always accessible via ${data}/${MAJOR}/${data}-latest.json
* PATCH is just applied to data files - version here is tracked by object storage versioning for historical purposes

2.Data Access Layer

Code version is described in dependency description or other way defined by DAL technology and installed. DAL code is bound to a MAJOR.MINOR version, thus data version is hardcoded.

### GD-3. tf_manager handles upload of latest version of a data file to the bucket

### GD-4. Apply versioning strategy for data and access layer as documented in VERSIONING.md (Sprint 3 product)

### GD-5. Tenancy key is auto-discovered

Tenancy key variable in tenancy client is optional. When not provided, key is discovered from OCI API (for a given access DAL) using already known tenancy_ocid and tenancy metadata. Works in similar way to auto-discovery of region from active connection.

Update tenancy DAL for shell, node, terraform.
Extend examples in README.

Bump minor version for DAL.

### GD-6. Synthetic data sets review

Let's take a look at realm, region, and tenancy json exemplary data. I need to review and rationalize this dataset towards useful demo data set. Currently avq3 tenancy key is hardcoded, which is a real tenancy active at my connection. I'd like test procedure (exemplary code, maybe client code) to map one of test data sets to  tenancy key, discovered at current OCI connection. This code should map with valid subscribed regions - possibly to the given limit e.g. 4 regions. Mapping to synthetic data is done in demo mode only, as in real situation must be supplied by data owner.

### GD-7. Add tenancy level field - list of private network CIDR associated with tenancy

### GD-8. Extend access to region's gdir_v2_regions_get_region_cidr_public to get: raw json, OSN json array, OBJECT_STORAGE JSON array, OCI json array

### GD-9. Extend tenancy schema with proxy.cert list

### GD-10. Restructure client directories

Current naming (`cli_client/`, `node_client/`, `tf_client/`, `tf_manager/`) mixes interface
types with technology names and uses inconsistent abbreviations. Restructure to a clean
grouped layout:

    clients/
      shell/       (was cli_client/ — shell library + examples)
      node/        (was node_client/ — TypeScript/Node.js library)
      terraform/   (was tf_client/ — Terraform modules + examples)
    manager/       (was tf_manager/ — provisions the OCI bucket)

Implementation: `git mv` each directory, update relative path references in 4 script files, update README.md and VERSIONING.md. Historical sprint docs are not updated.

### GD-11. Ansible client

Add `clients/ansible/` following the same DAL naming convention as other clients. Use Ansible's `uri` module, OCI Ansible collection, or OCI CLI to fetch catalog objects from OCI Object Storage. Structure:

    clients/ansible/
      roles/
        gdir_regions_v2/    (tasks, defaults)
        gdir_tenancies_v1/
        gdir_realms_v1/
      examples/
        region.yml
        tenancy.yml
      README.md

Prerequisite: GD-10 (directory restructure).

### GD-12. DAL High Availability — analysis and design

Current DAL has no resilience: single bucket, single region, no retry, no fallback,
session-only in-memory cache. Study the full option space and produce a design document
selecting the approach(es) to implement. Options to evaluate:

1. Retry + timeout — retry the same bucket on transient errors (baseline; no new infra)
2. Persistent local cache with stale fallback — cache fetched data to disk; serve stale copy on bucket failure (works for all data including tenant; no new infra)
3. Local data mode — formalize GDIR_DATA_DIR as a production-supported mechanism; add a sync-local helper that copies JSON from manager to a local directory (air-gap use)
4. Embedded static snapshot — bundle known-good snapshot of regions + realms with each client package as last-resort fallback (public/non-sensitive data only)
5. GitHub raw URL as fallback source — fetch from the manager git repo when OCI is unreachable (public/non-sensitive data only)
6. Secondary region bucket — upload to two OCI buckets; DAL fails over to secondary on primary failure (OCI native replication vs. dual tf_manager upload)

Design document must address: what failures each option protects against, data sensitivity constraints (tenant data must not go to GitHub or be embedded), cross-client consistency (same config knobs across bash, node, terraform), and recommended combination.

Product: option matrix + selected approach in sprint design doc.

### GD-13. DAL High Availability — implementation

Implement the approach selected in GD-12's design.

Expected minimum viable set: retry + timeout in all clients; persistent local cache with stale fallback; formalized local data mode (GDIR_DATA_DIR rename + sync helper).

Stretch (if selected in design): embedded static snapshot, GitHub fallback source, secondary region bucket.

Prerequisite: GD-12.

### GD-14. Data structure may reference external sources for an attribute

A field in the data structure may hold a *reference* to an external location (e.g. object path, URI) instead of inlining the value. Users should be able to tell at a glance that the value is a reference and where it points. The DAL should resolve the reference automatically (e.g. fetch the object or resource) and return the resolved content so callers do not need a second lookup.

```json
"cert": {
  "value": "MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEArandombase64==",
  "media_type": "application/x-x509-ca-cert",
  "encoding": "base64",
  "digest": "sha256:b3c89df1d1eae2",
  "source": "gdir://truststore/v1/certs/proxy-ca.pem"
}
```

### GD-15. DAL returns arrays with configurable separator

Add configurable to control separator used by array return. now it's new line - should be an argument. Potential existence of used separator in scalar value should be escaped.

### GD-16. Split data files into per-key files under domain/version subdirectories

The goal of this operation is enable per file CODEOWNERS support.

Replace monolithic data files (e.g. `tenancies_v1.json`, `regions_v2.json`, `realms_v1.json`) with a layout where each top-level key from the current data becomes a separate file under a domain and version subdirectory. File name = key name from the current data (e.g. tenancy key, region key, realm key).

Adjust DAL contracts abd client APIs. Perform all the tests to validate new data layout.

**Target layout (object path convention):**

- `<domain>/<version>/<key>.json` — one JSON file per key; file content = the single entity (e.g. one tenancy object, one region object, one realm object).

**Examples:**

- `tenancies/v1/acme_prod.json`, `tenancies/v1/demo_corp.json`, `tenancies/v1/avq3.json` (key = tenancy key)
- `regions/v2/eu-zurich-1.json`, `regions/v2/eu-frankfurt-1.json` (key = region key)
- `realms/v1/oc1.json`, `realms/v1/tst01.json` (key = realm key)

**Scope:** tf_manager produces and uploads the split files (from current or future monolithic source). Moreover retains a single “catalog” object per domain/version that lists keys (e.g. for discovery). DALs and clients either adopt the new layout (fetch per-key objects or catalog + key list).

### GD-17. Prepare terraform exemplary client fed by manager's outputs

Terraform client by default uses `gdir_info` bucket to get data. To make even simpler terraform client may directly use manager's outputs to get data. It's required to add outputs to manager terraform module to make it possible.

Exemplary code implements the same as other exemplary DAL programs.

Manager takes one more responsibility to maintain outputs, which in fact are copy of terraform's DAL logic. It should be implemented reusing DAL or combining terraform client with manager. Should be analyzed.

### GD-18. Remove last_updated_timestamp field

Remove `last_updated_timestamp` field from data, schema. Update manager, client, all docs. Perform tests.

