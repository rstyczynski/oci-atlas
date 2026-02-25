# Sprint 1 - Implementation Notes

## Implementation Overview

**Sprint Status:** implemented

**Backlog Items:**

- GD-1: Build foundation data model — tested

---

## GD-1. Build foundation data model

**Status:** tested

### Implementation Summary

Produced JSON Schema draft 2020-12 files for the two new data domains introduced by GD-1, plus corresponding example data files derived from `regions_v1.json`:

| Domain          | Schema file                    | Data file              |
| --------------- | ------------------------------ | ---------------------- |
| `regions/v2`    | `regions_v2.schema.json`       | `regions_v2.json`      |
| `tenancies/v1`  | `tenancies_v1.schema.json`     | `tenancies_v1.json`    |

The existing `regions/v1` and `realms/v1` domains are unchanged.

### Main Features

- **`regions/v2` schema**: physical region catalog only — `key` (short code), `realm`, and `network.public` (array of CIDR entries). Tenancy-specific attributes removed.
- **`tenancies/v1` schema**: tenancy catalog keyed by short tenancy name (e.g. `acme_prod`). Each tenancy declares its `realm` and a `regions` sub-map, keyed by full OCI region identifier (e.g. `eu-zurich-1`). Per-region attributes: `network.private`, `network.proxy`, `security.vault`, `toolchain.github.runner`, `observability`.
- **`propertyNames` pattern** on `tenancies/v1` regions sub-map enforces OCI region identifier format (`^[a-z]+-[a-z]+-[0-9]+$`).
- **`additionalProperties: false`** at every level in both schemas; `required` lists enforce mandatory fields.
- **Shared `$defs/cidr_entry`** reused across both schemas for CIDR array items (`cidr`, `description`, `tags`).
- **Cross-document association** documented via `$comment` in `tenancies_v1.schema.json`; referential integrity enforced by tooling outside JSON Schema (future GD-2).
- **Example data**: `regions_v2.json` contains all 12 regions from v1 (physical fields only). `tenancies_v1.json` contains the `acme_prod` tenancy (realm `oc1`) with 4 subscribed oc1 regions. `network.internal` renamed to `network.private` per v2 model.

### Design Compliance

Implementation follows the approved design in `sprint_1_design.md` exactly:

- Realm/region/tenancy separation as designed
- All attribute placements as specified in Q&A answers (sprint_1_openquestions.md)
- `propertyNames` pattern as designed
- `last_updated_timestamp` top-level property in both schemas

### Code Artifacts

| Artifact                      | Purpose                                      | Status   | Tested |
| ----------------------------- | -------------------------------------------- | -------- | ------ |
| `tf_manager/regions_v2.schema.json`    | JSON Schema for physical region catalog      | Complete | Yes    |
| `tf_manager/tenancies_v1.schema.json`  | JSON Schema for tenancy subscription catalog | Complete | Yes    |
| `tf_manager/regions_v2.json`           | Example data — 12 regions, physical fields   | Complete | Yes    |
| `tf_manager/tenancies_v1.json`         | Example data — acme_prod, 4 oc1 regions      | Complete | Yes    |

### Testing Results

**Functional Tests:** 11 / 11
**Edge Cases:** included in the 11 (3 negative, 4 positive, 2 compile, 2 JSON validity)
**Overall:** PASS

### Known Issues

None.

### User Documentation

#### Overview

`regions/v2` separates physical OCI region attributes (public CIDRs) from tenancy-specific attributes. `tenancies/v1` holds all tenancy-level per-region configuration. Together they replace the monolithic `regions/v1` structure.

#### Prerequisites

- `jq` installed
- `npx` / Node.js 18+ installed
- Working directory: `tf_manager/`

#### Usage

**Validate a regions/v2 document:**

```bash
npx ajv-cli@5 validate --spec=draft2020 \
  -s regions_v2.schema.json -d <your-regions-file.json>
```

**Validate a tenancies/v1 document:**

```bash
npx ajv-cli@5 validate --spec=draft2020 \
  -s tenancies_v1.schema.json -d <your-tenancies-file.json>
```

**Example — validate the bundled example data:**

```bash
npx ajv-cli@5 validate --spec=draft2020 -s regions_v2.schema.json   -d regions_v2.json
npx ajv-cli@5 validate --spec=draft2020 -s tenancies_v1.schema.json -d tenancies_v1.json
```

Expected output:

```text
regions_v2.json valid
tenancies_v1.json valid
```

#### Data Model Summary

**regions/v2 entry structure:**

```json
{
  "<oci-region-id>": {
    "key":    "<SHORT_CODE>",
    "realm":  "<realm-id>",
    "network": {
      "public": [
        { "cidr": "...", "description": "...", "tags": ["..."] }
      ]
    }
  }
}
```

**tenancies/v1 entry structure:**

```json
{
  "<tenancy-short-name>": {
    "realm": "<realm-id>",
    "regions": {
      "<oci-region-id>": {
        "network": {
          "private": [ { "cidr": "...", "description": "...", "tags": ["..."] } ],
          "proxy":   { "url": "...", "ip": "...", "port": "...", "noproxy": ["..."] }
        },
        "security":    { "vault": { "ocid": "...", "crypto_endpoint": "...", "management_endpoint": "..." } },
        "toolchain":   { "github": { "runner": { "labels": ["..."], "image": "..." } } },
        "observability": { "prometheus_scraping_cidr": "...", "loki_destination_cidr": "...", "loki_fqdn": "..." }
      }
    }
  }
}
```

#### Special Notes

- Tenancy name (e.g. `acme_prod`) is resolved by the OCI SDK at runtime; it is not provided manually.
- Region keys in `tenancies/v1.regions` must follow the OCI identifier format (`eu-zurich-1`). The short code (`ZRH`) is not valid and will be rejected by the schema.
- Cross-document referential integrity (tenancy region keys matching `regions/v2` entries) is enforced by tooling outside JSON Schema. See proposed change GD-2.

---

## Sprint Implementation Summary

### Overall Status

implemented

### Achievements

- Clean separation of physical (region) and operational (tenancy) attributes in versioned JSON schemas
- Strict schema structure with `additionalProperties: false` throughout
- OCI region identifier format enforced via `propertyNames` pattern in tenancies schema
- All 11 functional tests pass (100% success rate)
- Example data files validate cleanly against their respective schemas

### Challenges Encountered

- `ajv-cli@5` does not support stdin (`-d -`); resolved by using temp files for inline test data
- Column width alignment in PROGRESS_BOARD.md with long status values; resolved by widening column headers

### Test Results Summary

11 / 11 tests passed (100%) across schema validity, compile, positive validation, and negative validation cases.

### Integration Verification

- `regions/v1` and `realms/v1` files are unchanged; no existing clients are affected
- New schemas are additive; existing tf_manager tooling is unaffected

### Documentation Completeness

- Implementation docs: Complete
- Test docs: Complete
- User docs: Complete (this document)

### Ready for Production

Yes — schemas are complete, validated, and documented. Example data is provided and validated.
