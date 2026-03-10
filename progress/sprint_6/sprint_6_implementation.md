# Sprint 6 - Implementation Notes

## Implementation Overview

**Sprint Status:** implemented

**Backlog Items:**

- GD-6: tested

## GD-6. Synthetic Data Sets Review

Status: tested

### Implementation Summary

Rationalized the three synthetic demo data JSON files and created a new CLI demo mode
mapping script. All data inconsistencies identified in analysis have been resolved.

### Main Features

- **Data rationalization**: removed real tenancy key `avq3`, replaced with synthetic
  `demo_corp`; fixed `acme_prod` to use only realm-consistent regions; added missing
  `tst02` realm to fix referential integrity.
- **Demo mapping script**: `cli_client/examples/demo_mapping.sh` implements the demo
  mode mapping procedure with explicit guard (`GDIR_DEMO_MODE=true` required), tenant
  selection, region limiting, and clear "not for production" notice.

### Design Compliance

Implementation follows the approved design exactly:
- `avq3` replaced by `demo_corp` with matching structure
- `acme_prod` regions now only include `oc19`-realm regions (`af-region-2`, `eu-region-2`)
- `tst02` added to `realms_v1.json`
- Demo script requires `GDIR_DEMO_MODE=true` guard
- `template_data.regions` filtered to match `mapped_regions` limit

### Code Artifacts

| Artifact | Purpose | Status | Tested |
|----------|---------|--------|--------|
| `tf_manager/tenancies_v1.json` | Rationalized tenancies data | Complete | Yes |
| `tf_manager/realms_v1.json` | Added tst02 realm | Complete | Yes |
| `cli_client/examples/demo_mapping.sh` | Demo mode mapping script | Complete | Yes |
| `cli_client/test/run_tests.sh` | Updated region key for acme_prod tests | Complete | Yes |

### Testing Results

**Schema Validation Tests:** 3 / 3 passed
**CLI DAL Tests:** 20 / 20 passed (regression)
**Demo Mapping Tests:** 4 / 4 passed
**Error Case Tests:** 2 / 2 passed
**Realm Tests:** 1 / 1 passed
**Overall:** PASS (30 assertions)

### Known Issues

None.

### User Documentation

#### Overview

Sprint 6 delivers rationalized demo data for the Global Directory and a new demo mode
mapping procedure. The synthetic dataset is now internally consistent (realm references,
no real tenancy keys), and a CLI script allows mapping demo data to the current OCI
connection context.

#### Prerequisites

- `jq` installed on the host
- `bash` 4+
- For demo mapping with live OCI discovery: OCI CLI configured (`~/.oci/config`)
- For offline/local testing: set `GDIR_DATA_DIR=tf_manager`

#### Data Changes

**tenancies_v1.json:**

- Removed `avq3` (real tenancy key) → replaced with `demo_corp` (synthetic, realm `oc1`,
  region `eu-zurich-1`)
- Fixed `acme_prod` region list: now contains only `oc19`-realm regions:
  `af-region-2`, `eu-region-2`

**realms_v1.json:**

- Added `tst02` realm (fixes referential integrity with `tst-region-3` through
  `tst-region-6` in `regions_v2.json`)

#### Usage — Demo Mapping

**Basic Usage (requires OCI connection for tenancy key discovery):**

```bash
GDIR_DEMO_MODE=true bash cli_client/examples/demo_mapping.sh
```

**Offline Usage (explicit tenancy key):**

```bash
GDIR_DATA_DIR=tf_manager GDIR_DEMO_MODE=true TENANCY_KEY=demo_corp \
  bash cli_client/examples/demo_mapping.sh
```

**Options:**

- `GDIR_DEMO_MODE=true` — Required. Activates demo mode.
- `GDIR_DEMO_TENANT=<key>` — Template tenant (default: `acme_prod`).
- `GDIR_DEMO_MAX_REGIONS=<n>` — Max regions in output (default: `4`).
- `TENANCY_KEY=<key>` — Explicit tenancy key (skips OCI discovery).

**Example 1: Default demo mapping**

```bash
GDIR_DATA_DIR=tf_manager GDIR_DEMO_MODE=true TENANCY_KEY=acme_prod \
  bash cli_client/examples/demo_mapping.sh 2>/dev/null
```

Expected output:

```json
{
  "demo_mode": true,
  "real_tenancy_key": "acme_prod",
  "template_tenant": "acme_prod",
  "mapped_regions": ["af-region-2", "eu-region-2"],
  "template_data": { ... },
  "note": "Demo mode: synthetic tenant data mapped to real tenancy key. ..."
}
```

**Example 2: Limited regions with demo_corp as real tenancy**

```bash
GDIR_DATA_DIR=tf_manager GDIR_DEMO_MODE=true TENANCY_KEY=demo_corp \
  GDIR_DEMO_MAX_REGIONS=1 bash cli_client/examples/demo_mapping.sh 2>/dev/null
```

Expected output:

```json
{
  "demo_mode": true,
  "real_tenancy_key": "demo_corp",
  "template_tenant": "acme_prod",
  "mapped_regions": ["af-region-2"],
  "template_data": { "realm": "oc19", "regions": { "af-region-2": {...} } },
  "note": "Demo mode: ..."
}
```

**Example 3: Error — demo mode not enabled**

```bash
GDIR_DATA_DIR=tf_manager bash cli_client/examples/demo_mapping.sh
```

Expected output (stderr):

```
ERROR: Set GDIR_DEMO_MODE=true to enable demo mapping. This procedure is for demo/testing only.
  Example: GDIR_DEMO_MODE=true bash examples/demo_mapping.sh
```

#### Special Notes

- Demo mode output is ephemeral — no stored data is modified.
- In production, tenancy configuration data must be supplied by the data owner.
- The template tenant's data is filtered to show only the `mapped_regions` subset.

---

## Sprint Implementation Summary

### Overall Status

implemented

### Achievements

- Removed real tenancy identifier (`avq3`) from the public demo dataset — dataset is now
  fully synthetic and portable.
- Fixed realm consistency in `acme_prod` — regions now match the tenant's declared realm.
- Fixed referential integrity — `tst02` realm added to support tst-region-3 through -6.
- New demo mapping script with clear demo mode guard and explicit-override support.
- All 30 test assertions pass.

### Challenges Encountered

- Region limit filtering: initial implementation showed all template_data regions even
  when limit was set. Fixed by filtering `template_data.regions` to match `mapped_regions`
  using jq `with_entries(select(...))`.

### Test Results Summary

30 total assertions across 11 test cases — all pass.

### Integration Verification

- CLI DAL functions unchanged; no interface breaks.
- `run_tests.sh` updated to use `eu-region-2` (instead of removed `eu-zurich-1`) for
  `acme_prod` regression tests.

### Documentation Completeness

- Implementation docs: Complete
- Test docs: Complete
- User docs: Complete (above)

### Ready for Production

Yes — data changes are backwards-compatible for DAL interface; `avq3` key consumers need
to update to `demo_corp` if they relied on hardcoded key (this was the intent of the sprint).
