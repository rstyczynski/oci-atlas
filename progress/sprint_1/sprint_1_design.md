# Sprint 1 - Design

## GD-1. Build foundation data model

Status: Accepted

### Requirement Summary

Produce two new JSON Schema files that replace the mixed `regions_v1` model with a clean separation:

- `tf_manager/regions_v2.schema.json` — physical region attributes only (public CIDRs)
- `tf_manager/tenancies_v1.schema.json` — tenancy attributes with per-region subscription sub-map

`realms/v1` schema remains unchanged.

### Feasibility Analysis

**API Availability:**

No external API required. Deliverable is JSON Schema files only (draft 2020-12). The `ajv-cli` validator already installed in the project supports this standard.

**Technical Constraints:**

- Schema standard: JSON Schema draft 2020-12 (matches existing `regions_v1` and `realms_v1`)
- Strict validation: `additionalProperties: false` on all objects (matches existing convention)
- No data files in scope — schemas only; validation against data deferred to future sprint
- The tenancy regions sub-map uses OCI full region identifier as key (`eu-zurich-1` style), not the short code (`ZRH`). This is a data convention; JSON Schema `additionalProperties` pattern enforces the value structure but not the key format.

**Risk Assessment:**

- Low: Schema authoring is straightforward; no runtime dependency
- Low: Additive change — `regions_v1` stays intact, no consumers broken

### Design Overview

**Architecture:**

Three-domain model replacing the current two-domain model:

```
realms/v1      (unchanged)   →  realm attributes
regions/v2     (new)         →  physical region attributes (public CIDRs only)
tenancies/v1   (new)         →  tenancy + per-region subscription attributes
```

**Data Flow:**

A client authenticating as tenancy `acme_prod` in region `eu-zurich-1` can:

1. Look up `regions/v2[eu-zurich-1]` → public CIDRs for the physical region
2. Look up `tenancies/v1[acme_prod].regions[eu-zurich-1]` → proxy, vault, toolchain, observability

### Technical Specification

#### regions/v2 schema

Map keyed by region identifier. Each entry contains physical attributes only.

```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "$id": "regions/v2",
  "title": "regions/v2",
  "description": "OCI physical region attributes — public network CIDRs",
  "type": "object",
  "properties": {
    "last_updated_timestamp": {
      "type": "string",
      "description": "ISO 8601 UTC timestamp injected by tf_manager at upload time"
    }
  },
  "additionalProperties": {
    "type": "object",
    "required": ["key", "realm", "network"],
    "additionalProperties": false,
    "properties": {
      "key": {
        "type": "string",
        "description": "Short region code, e.g. ZRH, FRA"
      },
      "realm": {
        "type": "string",
        "description": "Realm the region belongs to, e.g. oc1"
      },
      "network": {
        "type": "object",
        "required": ["public"],
        "additionalProperties": false,
        "properties": {
          "public": {
            "type": "array",
            "description": "Public CIDR blocks published by Oracle for this region",
            "items": { "$ref": "#/$defs/cidr_entry" }
          }
        }
      }
    }
  },
  "$defs": {
    "cidr_entry": {
      "type": "object",
      "required": ["cidr", "description", "tags"],
      "additionalProperties": false,
      "properties": {
        "cidr":        { "type": "string" },
        "description": { "type": "string" },
        "tags":        { "type": "array", "items": { "type": "string" } }
      }
    }
  }
}
```

#### tenancies/v1 schema

Map keyed by tenancy short name. Each entry contains realm membership and a regions sub-map with tenancy-specific per-region attributes.

```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "$id": "tenancies/v1",
  "title": "tenancies/v1",
  "description": "OCI tenancy attributes — realm membership and per-region network, security, toolchain, observability",
  "type": "object",
  "properties": {
    "last_updated_timestamp": {
      "type": "string",
      "description": "ISO 8601 UTC timestamp injected by tf_manager at upload time"
    }
  },
  "additionalProperties": {
    "type": "object",
    "required": ["realm", "regions"],
    "additionalProperties": false,
    "properties": {
      "realm": {
        "type": "string",
        "description": "Realm this tenancy belongs to, e.g. oc1"
      },
      "regions": {
        "type": "object",
        "description": "Per-region subscription attributes, keyed by OCI region identifier (e.g. eu-zurich-1). Keys must correspond to entries in regions/v2 — enforced by data governance, not schema.",
        "$comment": "Region keys reference regions/v2 map keys. Cross-document referential integrity is validated by tooling outside JSON Schema.",
        "propertyNames": {
          "pattern": "^[a-z]+-[a-z]+-[0-9]+$",
          "description": "OCI region identifier format, e.g. eu-zurich-1"
        },
        "additionalProperties": {
          "type": "object",
          "required": ["network", "security", "toolchain", "observability"],
          "additionalProperties": false,
          "properties": {
            "network": {
              "type": "object",
              "required": ["private", "proxy"],
              "additionalProperties": false,
              "properties": {
                "private": {
                  "type": "array",
                  "description": "Private/internal CIDR blocks for this tenancy in this region",
                  "items": { "$ref": "#/$defs/cidr_entry" }
                },
                "proxy": {
                  "type": "object",
                  "required": ["url", "ip", "port", "noproxy"],
                  "additionalProperties": false,
                  "properties": {
                    "url":     { "type": "string" },
                    "ip":      { "type": "string" },
                    "port":    { "type": "string" },
                    "noproxy": { "type": "array", "items": { "type": "string" } }
                  }
                }
              }
            },
            "security": {
              "type": "object",
              "required": ["vault"],
              "additionalProperties": false,
              "properties": {
                "vault": {
                  "type": "object",
                  "required": ["ocid", "crypto_endpoint", "management_endpoint"],
                  "additionalProperties": false,
                  "properties": {
                    "ocid":                { "type": "string" },
                    "crypto_endpoint":     { "type": "string" },
                    "management_endpoint": { "type": "string" }
                  }
                }
              }
            },
            "toolchain": {
              "type": "object",
              "required": ["github"],
              "additionalProperties": false,
              "properties": {
                "github": {
                  "type": "object",
                  "required": ["runner"],
                  "additionalProperties": false,
                  "properties": {
                    "runner": {
                      "type": "object",
                      "required": ["labels", "image"],
                      "additionalProperties": false,
                      "properties": {
                        "labels": {
                          "type": "array",
                          "minItems": 1,
                          "items": { "type": "string" }
                        },
                        "image": { "type": "string" }
                      }
                    }
                  }
                }
              }
            },
            "observability": {
              "type": "object",
              "required": ["prometheus_scraping_cidr", "loki_destination_cidr", "loki_fqdn"],
              "additionalProperties": false,
              "properties": {
                "prometheus_scraping_cidr": { "type": "string" },
                "loki_destination_cidr":    { "type": "string" },
                "loki_fqdn":                { "type": "string" }
              }
            }
          }
        }
      }
    }
  },
  "$defs": {
    "cidr_entry": {
      "type": "object",
      "required": ["cidr", "description", "tags"],
      "additionalProperties": false,
      "properties": {
        "cidr":        { "type": "string" },
        "description": { "type": "string" },
        "tags":        { "type": "array", "items": { "type": "string" } }
      }
    }
  }
}
```

### Implementation Approach

**Step 1:** Create `tf_manager/regions_v2.schema.json` from the specification above.

**Step 2:** Create `tf_manager/tenancies_v1.schema.json` from the specification above.

**Step 3:** No data files, no Terraform, no DAL changes required in this sprint.

### Testing Strategy

**Functional Tests:**

1. Schema is valid JSON — parse both files with `jq .` (zero-exit confirms valid JSON)
2. Schema is valid JSON Schema — run `ajv compile` against each schema file
3. Schema rejects invalid documents — test with minimal malformed JSON (missing required fields)

**Success Criteria:**

Both schema files pass `ajv compile --spec=draft2020` without errors.

### Integration Notes

**Dependencies:** None — additive sprint, no existing consumer changes.

**Compatibility:** `regions_v1` and `realms_v1` are unchanged and remain fully operational.

**Reusability:** `cidr_entry` `$defs` pattern reused from `regions_v1` in both new schemas.

**DAL Implications (future sprint):**

The v2 data model requires a unified DAL that is aware of both `regions/v2` and `tenancies/v1` as data sources. Key constraints for the future DAL design:

1. **Tenancy name as required input** — the current DALs auto-discover region from the OCI SDK but have no tenancy name awareness. A v2 DAL must accept the tenancy short name (e.g. `acme_prod`) via configuration, environment variable, or OCI SDK tenancy OCID resolution.
2. **Two internal fetches, single external API** — a call to `getProxy()` or `getPublicCIDR()` must internally route to the correct domain (`tenancies/v1` or `regions/v2`) transparently to the caller.
3. **Cross-document key consistency** — the region identifier used as key in `tenancies/v1[*].regions` must match the key used in `regions/v2`. Enforced by data governance convention and future validation tooling, not by JSON Schema.

A `GD-2` backlog item is proposed in `sprint_1_proposedchanges.md` to cover the unified DAL implementation.

### Design Decisions

**Decision 1:** `network.private` in `tenancies/v1` mirrors `network.public` structure (array of `cidr_entry`)
**Rationale:** Consistent with existing pattern; allows tagged CIDR entries for private ranges.
**Alternatives Considered:** Plain array of CIDR strings — rejected for lack of metadata.

**Decision 2:** `tenancies/v1` has `realm` at tenancy level (not at region level)
**Rationale:** Per Product Owner answer — a tenancy belongs to one realm. Consistent with BACKLOG diagram.
**Alternatives Considered:** Multi-realm per tenancy — out of scope for v1.

**Decision 3:** `regions` sub-map in `tenancies/v1` uses `propertyNames` pattern + `additionalProperties`
**Rationale:** JSON Schema cannot enforce cross-file foreign-key relationships; key format (`eu-zurich-1`) is enforced by `propertyNames` pattern, while referential integrity (key must exist in `regions/v2`) is a data governance convention enforced by future validation tooling (see proposed GD-2).
**Alternatives Considered:** No key constraint at all — rejected as too permissive; enum of region names — rejected as brittle (requires schema update per new region).

### Open Design Questions

None.

---

# Design Summary

## Overall Architecture

Clean three-domain separation: `realms/v1` (realm) + `regions/v2` (physical region) + `tenancies/v1` (tenancy subscription). Physical and tenancy data no longer mixed.

## Shared Components

`cidr_entry` `$defs` structure reused identically in `regions/v2` and `tenancies/v1`.

## Design Risks

Low — schema-only sprint, no runtime impact.

## Resource Requirements

- `ajv-cli` (already installed via `npx ajv-cli@5`)
- `jq` (already installed for CLI client)

## Design Approval Status

Approved
