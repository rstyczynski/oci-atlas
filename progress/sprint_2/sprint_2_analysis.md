# Sprint 2 - Analysis

Status: Complete

## Sprint Overview

Remove the redundant `realm` attribute from the `tenancies/v1` data model. The fix applies to both the JSON Schema file and the data file to keep them consistent.

## Backlog Items Analysis

### GD-1-fix1. Remove `realm` attribute from tenancies json data file

**Requirement Summary:**

The `realm` field currently exists at the tenancy level in `tenancies_v1.json` (e.g. `acme_prod.realm = "oc1"`). It is redundant: realm membership is already discoverable from `regions/v2` since every region entry carries a `realm` field, and all regions a tenancy subscribes to share the same realm. Removing `realm` from `tenancies/v1` simplifies the model.

**Current State:**

| File | Current content | Required change |
| ---- | --------------- | --------------- |
| `tf_manager/tenancies_v1.json` | `"realm": "oc1"` at tenancy level | Remove the field |
| `tf_manager/tenancies_v1.schema.json` | `"required": ["realm", "regions"]` + `realm` in `properties` | Remove from required + properties |

**Technical Approach:**

Removing `realm` from the data file without changing the schema would fail validation because `realm` is in the `required` array. The fix is two-part:

1. In `tenancies_v1.schema.json`: remove `"realm"` from `required` and from `properties`
2. In `tenancies_v1.json`: remove `"realm": "..."` from each tenancy entry

**Dependencies:**

GD-1 (Sprint 1, done). Both files must exist — confirmed present in `tf_manager/`.

**Testing Strategy:**

1. Validate updated `tenancies_v1.json` against updated `tenancies_v1.schema.json` — must pass
2. Confirm that adding `"realm"` back to the data file causes rejection (`additionalProperties: false`)
3. Confirm schema still rejects data with missing `regions` field

**Risks/Concerns:**

None — no DAL clients consume `tenancies/v1` yet (no DAL for this domain exists).

**Compatibility Notes:**

`regions/v1`, `realms/v1`, `regions/v2` schemas and data files are completely unchanged. The `tenancies_v1.schema.json` change is a minor breaking change (removes a previously required field), but blast radius is zero since no consumer exists.

## Overall Sprint Assessment

**Feasibility:** High — two targeted line deletions in existing files.

**Estimated Complexity:** Simple — schema property removal + data field removal.

**Prerequisites Met:** Yes — GD-1 complete, both files validated and tested.

**Open Questions:** None.

## Recommended Design Focus Areas

- Confirm `additionalProperties: false` still blocks `realm` if accidentally included in data
- Verify existing tests remain green after the schema change

## Readiness for Design Phase

Confirmed Ready — no open questions. Proceeding to Elaboration.
