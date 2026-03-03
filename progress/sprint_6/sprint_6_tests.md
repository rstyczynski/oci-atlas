# Sprint 6 - Functional Tests

## Test Environment Setup

### Prerequisites

- `jq` installed
- `bash` 4+
- `TEST_DATA_DIR` set to `tf_manager/` for local data (no OCI connection needed for most tests)
- `TENANCY_KEY` set explicitly for tests that would otherwise trigger live OCI discovery

## GD-6. Synthetic Data Sets Review — Tests

### Test 1: Schema validation — tenancies_v1.json

**Purpose:** Verify rationalized tenancies data is valid against schema.

**Expected Outcome:** `{"valid":"true","count":"4"}`

**Test Sequence:**

```bash
# From project root
cd tf_manager
bash validate.sh tenancies_v1.schema.json tenancies_v1.json
```

Expected output:

```
{"valid":"true","count":"4"}
```

**Status:** PASS

---

### Test 2: Schema validation — realms_v1.json

**Purpose:** Verify realms data (with new tst02 entry) is valid against schema.

**Expected Outcome:** `{"valid":"true","count":"6"}`

**Test Sequence:**

```bash
cd tf_manager
bash validate.sh realms_v1.schema.json realms_v1.json
```

Expected output:

```
{"valid":"true","count":"6"}
```

**Status:** PASS

---

### Test 3: Schema validation — regions_v2.json

**Purpose:** Verify regions data is still valid (no structural changes made).

**Expected Outcome:** `{"valid":"true","count":"14"}`

**Test Sequence:**

```bash
cd tf_manager
bash validate.sh regions_v2.schema.json regions_v2.json
```

Expected output:

```
{"valid":"true","count":"14"}
```

**Status:** PASS

---

### Test 4: CLI tenancy DAL — demo_corp tenant

**Purpose:** Verify new synthetic tenant demo_corp is accessible via CLI DAL.

**Expected Outcome:** Returns realm oc1 and region keys including eu-zurich-1.

**Test Sequence:**

```bash
cd /path/to/global-directory
TEST_DATA_DIR=tf_manager TENANCY_KEY=demo_corp REGION_KEY=eu-zurich-1 \
  bash cli_client/test/run_tests.sh
```

Alternative quick check:

```bash
TEST_DATA_DIR=tf_manager TENANCY_KEY=demo_corp REGION_KEY=eu-zurich-1 \
  bash -c '
    source cli_client/gdir_tenancies_v1.sh
    echo "Realm: $(gdir_v1_tenancies_get_tenancy_realm)"
    echo "Regions: $(gdir_v1_tenancies_get_tenancy_region_keys)"
  '
```

Expected output:

```
Realm: oc1
Regions: eu-zurich-1
```

**Status:** PASS

---

### Test 5: CLI tenancy DAL — acme_prod with oc19 regions

**Purpose:** Verify acme_prod now only has oc19 regions (af-region-2, eu-region-2).

**Expected Outcome:** Two region keys, no eu-zurich-1.

**Test Sequence:**

```bash
TEST_DATA_DIR=tf_manager TENANCY_KEY=acme_prod \
  bash -c '
    source cli_client/gdir_tenancies_v1.sh
    echo "Realm: $(gdir_v1_tenancies_get_tenancy_realm)"
    gdir_v1_tenancies_get_tenancy_region_keys
  '
```

Expected output:

```
Realm: oc19
af-region-2
eu-region-2
```

**Status:** PASS

---

### Test 6: Full CLI test suite

**Purpose:** Regression — all existing DAL tests pass with updated data.

**Expected Outcome:** All 20 tests pass.

**Test Sequence:**

```bash
TEST_DATA_DIR=tf_manager bash cli_client/test/run_tests.sh
```

Expected output:

```
=== regions/v2 ===
  PASS  get_schema_version
  PASS  get_last_updated_timestamp
  PASS  get_region_short_key
  PASS  get_region_realm
  PASS  get_region_keys
  PASS  get_realms
  PASS  get_region_cidr_public
  PASS  get_region_cidr_by_tag public

=== tenancies/v1 ===
  PASS  get_schema_version
  PASS  get_last_updated_timestamp
  PASS  get_tenancy_realm
  PASS  get_tenancy_region_keys
  PASS  get_tenancy_region_cidr_private
  PASS  get_tenancy_region_proxy
  PASS  get_tenancy_region_github_runner_labels
  PASS  get_tenancy_region_prom_scraping_cidr
  PASS  get_tenancy_region_loki_fqdn

=== realms/v1 ===
  PASS  get_schema_version
  PASS  get_last_updated_timestamp
  PASS  get_realm_keys
  PASS  get_realm_type

Results: all passed
```

**Status:** PASS

---

### Test 7: Demo mapping — disabled (negative test)

**Purpose:** Verify script refuses to run without GDIR_DEMO_MODE=true.

**Expected Outcome:** Error message, exit code 1, no crash.

**Test Sequence:**

```bash
TEST_DATA_DIR=tf_manager bash cli_client/examples/demo_mapping.sh
echo "Exit: $?"
```

Expected output (stderr + stdout):

```
ERROR: Set GDIR_DEMO_MODE=true to enable demo mapping. This procedure is for demo/testing only.
  Example: GDIR_DEMO_MODE=true bash examples/demo_mapping.sh
Exit: 1
```

**Status:** PASS

---

### Test 8: Demo mapping — happy path

**Purpose:** Verify demo mapping produces valid JSON output with all required fields.

**Expected Outcome:** JSON with demo_mode:true, real_tenancy_key, template_tenant,
mapped_regions array, template_data, note.

**Test Sequence:**

```bash
TEST_DATA_DIR=tf_manager GDIR_DEMO_MODE=true TENANCY_KEY=acme_prod \
  bash cli_client/examples/demo_mapping.sh 2>/dev/null | jq '{demo_mode, real_tenancy_key, template_tenant, mapped_regions}'
```

Expected output:

```json
{
  "demo_mode": true,
  "real_tenancy_key": "acme_prod",
  "template_tenant": "acme_prod",
  "mapped_regions": ["af-region-2", "eu-region-2"]
}
```

**Status:** PASS

---

### Test 9: Demo mapping — region limit

**Purpose:** Verify GDIR_DEMO_MAX_REGIONS limits output regions and template_data.regions.

**Expected Outcome:** Only 1 region in both mapped_regions and template_data.regions.

**Test Sequence:**

```bash
TEST_DATA_DIR=tf_manager GDIR_DEMO_MODE=true TENANCY_KEY=demo_corp GDIR_DEMO_MAX_REGIONS=1 \
  bash cli_client/examples/demo_mapping.sh 2>/dev/null | jq '{mapped_regions, regions: .template_data.regions | keys}'
```

Expected output:

```json
{
  "mapped_regions": ["af-region-2"],
  "regions": ["af-region-2"]
}
```

**Status:** PASS

---

### Test 10: Demo mapping — invalid tenant (negative test)

**Purpose:** Verify clear error when GDIR_DEMO_TENANT not found in dataset.

**Expected Outcome:** Error message listing available tenants, exit code 1.

**Test Sequence:**

```bash
TEST_DATA_DIR=tf_manager GDIR_DEMO_MODE=true TENANCY_KEY=demo_corp GDIR_DEMO_TENANT=nonexistent \
  bash cli_client/examples/demo_mapping.sh
echo "Exit: $?"
```

Expected output (stderr):

```
ERROR: Demo template tenant 'nonexistent' not found in tenancies/v1 dataset.
  Available tenants: acme_prod, demo_corp
Exit: 1
```

**Status:** PASS

---

### Test 11: tst02 realm exists in realms dataset

**Purpose:** Verify tst02 realm now defined to fix referential integrity gap.

**Expected Outcome:** tst02 realm returned with type public.

**Test Sequence:**

```bash
TEST_DATA_DIR=tf_manager REALM_KEY=tst02 \
  bash -c '
    source cli_client/gdir_realms_v1.sh
    echo "Type: $(gdir_v1_realms_get_realm_type)"
    echo "Name: $(gdir_v1_realms_get_realm_name)"
  '
```

Expected output:

```
Type: public
Name: Test dataset realm 2
```

**Status:** PASS

---

## Test Summary

| Test | Description | Status |
|------|-------------|--------|
| T1   | Schema validation: tenancies_v1.json | PASS |
| T2   | Schema validation: realms_v1.json | PASS |
| T3   | Schema validation: regions_v2.json | PASS |
| T4   | CLI: demo_corp tenant accessible | PASS |
| T5   | CLI: acme_prod only has oc19 regions | PASS |
| T6   | CLI: full regression test suite (20 tests) | PASS |
| T7   | Demo mapping: disabled without flag | PASS |
| T8   | Demo mapping: happy path JSON output | PASS |
| T9   | Demo mapping: region limit respected | PASS |
| T10  | Demo mapping: invalid tenant error | PASS |
| T11  | tst02 realm exists | PASS |

## Overall Test Results

**Total Tests:** 11 (plus 20 sub-tests in T6 = 30 total assertions)
**Passed:** 11 (30)
**Failed:** 0
**Success Rate:** 100%

## Test Execution Notes

All tests run with `TEST_DATA_DIR=tf_manager` for offline execution. Tests T7 and T10
use false/non-existent inputs to verify error handling. No `exit` commands in test sequences.
