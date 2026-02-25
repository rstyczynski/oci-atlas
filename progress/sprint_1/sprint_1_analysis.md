# Sprint 1 - Analysis

Status: In Progress

## Sprint Overview

Produce a v2 JSON Schema data model that cleanly separates three OCI entities — Realm, Region, Tenancy — and their relationships, enabling clients to discover proxy, prometheus, and github attributes from an OCI security context (a connection = authenticated tenancy + current region). No provisioning, no DAL clients in scope.

## Backlog Items Analysis

### GD-1. Build foundation data model

**Requirement Summary:**

Produce JSON Schema v2 files reflecting the tuple (realm, region, tenancy). The current `regions_v1` schema conflates physical-region attributes (public/internal CIDRs) with tenancy-specific attributes (proxy, vault, toolchain, observability). The v2 model must separate these properly.

**Current State (regions_v1 field classification):**

| Field | Nature | Target in v2 |
|-------|--------|-------------|
| `key` | Physical | `regions/v2` |
| `realm` | Relationship | `regions/v2` |
| `network.public` | Physical (OCI-published) | `regions/v2` |
| `network.internal` | Physical | `regions/v2` |
| `network.proxy` | Tenancy-specific | TBD — see Open Questions |
| `security.vault` | Tenancy-specific (OCID is per-tenancy) | TBD |
| `toolchain.github.runner` | Tenancy-specific | TBD |
| `observability.prometheus_scraping_cidr` | Physical region CIDR | `regions/v2` |
| `observability.loki_destination_cidr` | Tenancy-specific | TBD |
| `observability.loki_fqdn` | Tenancy-specific | TBD |

**`realms/v1` assessment:** Clean — all fields are physical realm properties. Either reuse as-is or produce `realms/v2` if structural changes are needed.

**Technical Approach:**

Produce three new schema files:

- `tf_manager/regions_v2.schema.json` — physical region attributes only
- `tf_manager/realms_v2.schema.json` — realm attributes (may be identical to v1 or extended)
- `tf_manager/tenancies_v1.schema.json` — tenancy attributes, including per-region subscription data

Document conventions match existing schemas: `$schema: draft 2020-12`, `additionalProperties: false`, `$id: <domain>/<version>`.

**Dependencies:**

None — this is Sprint 1. Produces schemas only; no dependency on existing provisioning or DAL code.

**Testing Strategy:**

Schema files are the deliverable. Validation is by review (managed mode) — the analyst confirms the schema is internally consistent and correctly models the tuple (realm, region, tenancy). No ajv-cli validation run in this sprint (no data files produced).

**Risks/Concerns:**

1. The M:N subscription relationship between REGION and TENANCY: proxy/vault/toolchain/observability attributes logically belong to the subscription (junction entity), not to the tenancy itself. If modelled incorrectly, the schema will not support multi-tenancy or multi-region scenarios cleanly. See Open Questions below.

2. Tenancy identifier: the current model has no explicit tenancy key. The v2 model needs one. What form should it take (tenancy OCID? short name? both)?

**Compatibility Notes:**

This sprint produces v2 schemas only. `regions_v1` and `realms_v1` schemas are unchanged and remain fully operational. There is no breaking change to existing consumers. Migration is deferred to future sprints.

## Overall Sprint Assessment

**Feasibility:** High — JSON Schema authoring is straightforward; the conceptual model is well understood.

**Estimated Complexity:** Moderate — the structural separation is clear but the placement of tenancy-scoped per-region attributes (proxy, vault, toolchain, observability) requires a design decision: model them inside the tenancy document as a region-keyed sub-map, or introduce a separate `subscriptions/v1` domain (junction table between tenancy and region).

**Prerequisites Met:** Yes — existing schemas reviewed, current field classification completed.

**Open Questions:**

See `sprint_1_openquestions.md` for formal tracking.

1. **Where do tenancy-scoped per-region attributes live?**
The attributes proxy, vault, toolchain.github, observability.loki belong to the intersection of tenancy × region (a "subscription" or "connection"). Two modelling options:
   - Option A: Inside `tenancies/v1` as `{region_key → {proxy, vault, toolchain, observability}}`
   - Option B: Separate `subscriptions/v1` domain keyed by `(tenancy_key, region_key)`
Which approach does the Product Owner prefer?

2. **What is the tenancy identifier/key?**
The tenancy key in the schema must be a stable, human-usable identifier. Options:
   - Short name (e.g., `avq_prod`)
   - Tenancy OCID (globally unique but long)
   - Both (short name as key, OCID as a field)
Which form should the tenancy key take?

3. **Should `realms/v2` differ from `realms/v1`?**
The current `realms/v1` schema appears correct and complete. Should the product include a `realms/v2` (even if identical), or is `realms/v1` kept as-is and only `regions/v2` and `tenancies/v1` are new?

## Recommended Design Focus Areas

- Tenancy identifier convention (must be decided before schema can be written)
- Placement of M:N junction attributes (Option A vs Option B above)
- Naming of the new tenancy domain (`tenancies` or `connections` or `subscriptions`)

## Readiness for Design Phase

Awaiting Clarification — three open questions must be answered before schema design can begin.
