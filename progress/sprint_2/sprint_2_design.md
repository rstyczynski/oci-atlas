# Sprint 2 - Design

## GD-1-fix1. Remove `realm` attribute from tenancies json data file

Status: Accepted

### Requirement Summary

Remove the redundant `realm` field from the `tenancies/v1` model. The field exists at the tenancy level but is already encoded in `regions/v2` for each subscribed region. Removing it simplifies the model and eliminates the possibility of `realm` values diverging between `regions/v2` and `tenancies/v1`.

### Feasibility Analysis

**API Availability:**

No external API required. The deliverable is a targeted edit to two existing JSON files.

**Technical Constraints:**

- `additionalProperties: false` in `tenancies_v1.schema.json` means any extra field in data is rejected at validation time — once `realm` is removed from `properties`, re-adding it to data will be caught automatically.
- `required` array removal is sufficient to make the field non-required; removing from `properties` as well enforces that the field is forbidden (due to `additionalProperties: false`).

**Risk Assessment:**

- Low: no DAL client exists for `tenancies/v1` — zero consumer impact.
- Low: additive compatibility in reverse — old data with `realm` will fail the new schema; but since this is the first and only data file in the project, no migration is needed.

### Design Overview

**Two-file edit:**

| File | Change |
| ---- | ------ |
| `tf_manager/tenancies_v1.schema.json` | Remove `"realm"` from `required` array; remove `realm` from `properties` block |
| `tf_manager/tenancies_v1.json` | Remove `"realm": "<value>"` line from each tenancy entry |

**Before / After (schema `additionalProperties` block):**

Before:
```json
"required": ["realm", "regions"],
"additionalProperties": false,
"properties": {
  "realm": {
    "type": "string",
    "description": "Realm this tenancy belongs to, e.g. oc1"
  },
  "regions": { ... }
}
```

After:
```json
"required": ["regions"],
"additionalProperties": false,
"properties": {
  "regions": { ... }
}
```

**Before / After (data file):**

Before:
```json
"acme_prod": {
  "realm": "oc1",
  "regions": { ... }
}
```

After:
```json
"acme_prod": {
  "regions": { ... }
}
```

### Implementation Approach

**Step 1:** Edit `tf_manager/tenancies_v1.schema.json` — remove `realm` from `required` and `properties`.

**Step 2:** Edit `tf_manager/tenancies_v1.json` — remove `"realm"` line from `acme_prod` entry.

**Step 3:** Run validation tests to confirm schema and data are consistent.

### Testing Strategy

**Functional Tests:**

1. `tenancies_v1.json` validates against updated `tenancies_v1.schema.json` — must PASS
2. A document with `"realm"` field present is rejected (`additionalProperties: false`) — must FAIL validation
3. A document missing `regions` is rejected — must FAIL validation (regression guard)
4. Schema compiles cleanly with `ajv compile --spec=draft2020` — must PASS

**Success Criteria:**

Updated `tenancies_v1.json` passes schema validation; a document with `realm` fails.

### Integration Notes

**Dependencies:** GD-1 (Sprint 1, done).

**Compatibility:** `regions/v1`, `realms/v1`, `regions/v2` unchanged.

**Reusability:** Testing pattern reuses existing `ajv-cli@5` toolchain from Sprint 1.

### Design Decisions

**Decision 1:** Remove `realm` from both `required` and `properties` (not just make it optional).
**Rationale:** Since `additionalProperties: false` is enforced, removing from `properties` means any data file that still contains `realm` will fail validation — a useful guard against accidental reintroduction.
**Alternatives Considered:** Mark `realm` optional — rejected because it would silently accept old data rather than catching stale files.

### Open Design Questions

None.

---

# Design Summary

## Overall Architecture

Targeted two-file edit. No structural change to the three-domain model; this is a field removal cleanup.

## Design Risks

Low — isolated change, no consumers.

## Resource Requirements

- `ajv-cli` (already installed via `npx ajv-cli@5`)
- `jq` (for JSON syntax check)

## Design Approval Status

Accepted
