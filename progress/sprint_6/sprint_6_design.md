# Sprint 6 - Design

## GD-6. Synthetic data sets review

Status: Proposed

### Requirement Summary

Review and rationalize the synthetic demo data files (`tenancies_v1.json`,
`realms_v1.json`, `regions_v2.json`) and create a demo mode mapping procedure (CLI
exemplary script) that maps the auto-discovered real tenancy key to a synthetic template
dataset, limited to a configurable number of subscribed regions.

### Feasibility Analysis

**API Availability:**

- Tenancy key discovery: `oci os ns get-metadata` and `oci iam tenancy get` — already
  validated in Sprint 5 (CLI, Node.js, Terraform).
- Region subscription list: `oci iam region-subscription list --tenancy-id <ocid>` — a
  standard OCI CLI call available in all commercial and sovereign realms.
- JSON manipulation: `jq` — already used throughout CLI client.
- Schema validation: `tf_manager/validate.sh` — already in place.

**Technical Constraints:**

- `jq` must be available on the host.
- OCI CLI with valid `~/.oci/config` (or instance principal) must be configured.
- For region subscription list, IAM `read` permission on tenancy is required (standard
  for any OCI user with basic access).

**Risk Assessment:**

- **R1**: Region intersection empty — synthetic region keys (e.g., `eu-region-1`) won't
  match real OCI region names (e.g., `eu-zurich-1`). Mitigation: use template tenant's own
  region list directly (with limit), since the mapping is demo/exemplary only; add a note
  explaining the substitution.
- **R2**: `avq3` removal may break Sprint 5 tests that rely on `avq3` existing in
  `tenancies_v1.json`. Mitigation: update affected tests to use `demo_corp` or the
  dynamically discovered key.
- **R3**: Schema breaking change if new synthetic tenant structure diverges from schema.
  Mitigation: validate after each data change.

### Design Overview

**Architecture:**

Two independent deliverables:

1. **Data rationalization** — in-place fixes to three JSON files plus `validate.sh`
   verification.
2. **Demo mapping script** — new Bash script in `cli_client/examples/` that uses existing
   DAL functions plus a new `oci iam region-subscription list` call.

**Key Components:**

1. `tf_manager/tenancies_v1.json` — rationalized dataset (remove `avq3`, add `demo_corp`,
   fix `acme_prod` regions to match realm `oc19`).
2. `tf_manager/realms_v1.json` — add `tst02` realm definition.
3. `tf_manager/regions_v2.json` — no structural change needed; `tst-region-*` already have
   correct structure, only missing realm definition fixed in realms file.
4. `cli_client/examples/demo_mapping.sh` — new demo mode mapping example script.

**Data Flow (demo mapping):**

```
GDIR_DEMO_MODE=true
        │
        ▼
discover real tenancy key (Sprint 5 mechanism)
        │
        ▼
select template tenant from dataset (GDIR_DEMO_TENANT, default: acme_prod)
        │
        ▼
get template tenant's region list from tenancies_v1
        │
        ▼
limit to first N regions (GDIR_DEMO_MAX_REGIONS, default: 4)
        │
        ▼
output JSON: { demo_tenancy_key: <real_key>, template: <acme_prod>, regions: [...] }
```

### Technical Specification

**Data Changes:**

*tenancies_v1.json*:

- Remove `avq3` entry.
- Add `demo_corp` entry with realm `oc1`, one region `eu-zurich-1`, with synthetic (but
  plausible) values for network/security/toolchain/observability fields:
  - Proxy: `http://proxy.demo-corp.example.com:8080` / IP `10.100.0.100` / port `8080`
  - Vault OCID: `ocid1.vault.oc1.eu-zurich-1.demo0000000001`
  - GitHub runner image: `ocid1.image.oc1.eu-zurich-1.demo0000000001`
- Fix `acme_prod`: replace region list so all regions belong to realm `oc19`.
  From `regions_v2.json`, realm `oc19` regions are: `af-region-2`, `eu-region-2`.
  Remove `af-region-1`, `eu-region-1`, `eu-region-3`, `eu-zurich-1` (all `oc1`) and keep
  only `af-region-2` and `eu-region-2` (both `oc19`). Keep data structure consistent.

*realms_v1.json*:

- Add `tst02` entry:

```json
"tst02": {
  "api_domain": "test2.oraclecloud.com",
  "description": "Non-existing test dataset realm 2",
  "geo-region": "test",
  "name": "Test dataset realm 2",
  "type": "public"
}
```

**Demo Mapping Script:**

File: `cli_client/examples/demo_mapping.sh`

Interface:

- `GDIR_DEMO_MODE` — must be `true`; script exits with error if unset/false.
- `GDIR_DEMO_TENANT` — synthetic template tenant key (default: `acme_prod`).
- `GDIR_DEMO_MAX_REGIONS` — maximum regions to include (default: `4`).
- `TENANCY_KEY` — optional explicit tenancy key override (passed to existing discovery).

Output format:

```json
{
  "demo_mode": true,
  "real_tenancy_key": "<discovered_key>",
  "template_tenant": "acme_prod",
  "mapped_regions": ["eu-region-2", "af-region-2"],
  "note": "Demo mode: synthetic tenant 'acme_prod' data mapped to real tenancy key. Not for production use."
}
```

**Error Handling:**

- `GDIR_DEMO_MODE` not `true` → `ERROR: Set GDIR_DEMO_MODE=true to enable demo mapping.`
- Tenancy key discovery fails → propagate error from Sprint 5 discovery function.
- Template tenant not found in dataset → `ERROR: Demo template tenant 'X' not found.`
- Zero regions in template after limit → `WARNING: No regions available; increase limit.`

### Implementation Approach

**Step 1:** Fix `realms_v1.json` — add `tst02` realm.

**Step 2:** Fix `tenancies_v1.json`:
  - Remove `avq3`.
  - Replace `acme_prod` region list with `oc19`-realm regions only (`af-region-2`,
    `eu-region-2`).
  - Add `demo_corp` synthetic tenant.

**Step 3:** Run `tf_manager/validate.sh` to confirm schema compliance.

**Step 4:** Implement `cli_client/examples/demo_mapping.sh`.

**Step 5:** Update `cli_client/examples/tenancy.sh` comment to reference `demo_corp`
instead of `avq3` (if any references exist).

**Step 6:** Check if any existing tests reference `avq3` and update to `demo_corp`.

### Testing Strategy

**Functional Tests:**

1. Schema validation: `cd tf_manager && bash validate.sh` — expect all VALID.
2. CLI data access with `acme_prod`: `TENANCY_KEY=acme_prod REGION_KEY=af-region-2 bash
   examples/tenancy.sh` — expect network/proxy/vault output.
3. CLI data access with `demo_corp`: `TENANCY_KEY=demo_corp REGION_KEY=eu-zurich-1 bash
   examples/tenancy.sh` — expect demo_corp data output.
4. Demo mapping happy path: `GDIR_DEMO_MODE=true bash examples/demo_mapping.sh` —
   expect JSON output with `demo_mode: true` and `real_tenancy_key`.
5. Demo mapping disabled: `bash examples/demo_mapping.sh` (no GDIR_DEMO_MODE) —
   expect error message, no crash.
6. Custom tenant/limit: `GDIR_DEMO_MODE=true GDIR_DEMO_TENANT=acme_prod
   GDIR_DEMO_MAX_REGIONS=2 bash examples/demo_mapping.sh` — expect max 2 regions.

**Edge Cases:**

1. Template tenant not in dataset — error message, no crash.
2. `GDIR_DEMO_MAX_REGIONS=0` — warn and fall back to 1.

**Success Criteria:**

- All schemas validate without errors after data changes.
- Demo mapping script produces valid JSON with `demo_mode: true`.
- Error cases print clear, actionable messages.
- No `exit` commands in copy-paste examples.

### Integration Notes

**Dependencies:**

- Sprint 5 tenancy key discovery logic (CLI: `_gdir_v1_tenancies_resolved_key`).
- `jq` (already required by CLI DAL).

**Compatibility:**

- Removing `avq3` from `tenancies_v1.json` is a breaking data change for any consumer
  that specifically looks up `avq3`. Existing DAL interfaces unchanged.
- `acme_prod` structure changes (fewer regions) — consumers using `acme_prod` with
  `eu-zurich-1` region key will no longer find that region. Tests must be updated.

**Reusability:**

- `demo_mapping.sh` reuses `gdir_tenancies_v1.sh` functions.
- No new DAL functions needed; script is purely a usage example.

### Documentation Requirements

**User Documentation:**

- `demo_mapping.sh` usage and env vars in the script header and `implementation.md`.
- Data rationalization changes documented in `implementation.md`.

**Technical Documentation:**

- Explain the demo mode concept: synthetic data + runtime mapping, not for production.
- Note the realm consistency fix and its rationale.

### Design Decisions

**Decision 1:** Replace `avq3` with `demo_corp` (not delete)
**Rationale:** Keeps the dataset with two tenants of different complexity (multi-region
`acme_prod`, single-region `demo_corp`), making demos more useful.

**Decision 2:** CLI-only for demo mapping script (not Node.js)
**Rationale:** The backlog says "exemplary code, maybe client code" — CLI example is the
minimal interpretation; Node.js can be added in a later sprint if needed.

**Decision 3:** Use template's own region list (not real OCI subscriptions)
**Rationale:** Real OCI region names won't match synthetic keys; using template regions
directly with a limit provides a consistent, offline-capable demo.

**Decision 4:** `tst02` added to realms_v1.json with same structure as `tst01`
**Rationale:** Fixes referential integrity; uses test-appropriate values.

### Open Design Questions

None — all four open questions from inception resolved by design decisions above (see
decisions 1–4). Proceeding with design.

---

# Design Summary

## Overall Architecture

Two deliverables: (1) rationalized JSON data files and (2) new CLI demo mapping example.
No DAL interface changes. No Terraform or Node.js changes in this sprint.

## Shared Components

- `gdir_tenancies_v1.sh` functions reused by `demo_mapping.sh`.
- `validate.sh` used to verify data integrity after changes.

## Design Risks

- `avq3` removal may require test updates — mitigated by replacing with `demo_corp`.
- Real vs. synthetic region key mismatch in demo mapping — mitigated by using template
  regions directly.

## Resource Requirements

- `jq`, `bash`, OCI CLI (for live demo mapping execution).
- No new dependencies.

## Design Approval Status

Awaiting Review
