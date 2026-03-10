# Sprint 8 - Tests

## GD-18: Remove last_updated_timestamp field

Status: Tested

### Shell Tests

```
GDIR_DATA_DIR=$PWD/manager bash clients/shell/test/run_tests.sh
```

**Result: 18/18 passed**

```
=== regions/v2 ===
  PASS  get_schema_version
  PASS  get_region_short_key
  PASS  get_region_realm
  PASS  get_region_keys
  PASS  get_realms
  PASS  get_region_cidr_public
  PASS  get_region_cidr_by_tag public

=== tenancies/v1 ===
  PASS  get_schema_version
  PASS  get_tenancy_realm
  PASS  get_tenancy_region_keys
  PASS  get_tenancy_region_cidr_private
  PASS  get_tenancy_region_proxy
  PASS  get_tenancy_region_github_runner_labels
  PASS  get_tenancy_region_prom_scraping_cidr
  PASS  get_tenancy_region_loki_fqdn

=== realms/v1 ===
  PASS  get_schema_version
  PASS  get_realm_keys
  PASS  get_realm_type

Results: 18 passed, 0 failed (all passed)
```

3 timestamp tests removed (as designed). Sprint 7 had 21 tests; Sprint 8 has 18.

### Node Tests

```
GDIR_DATA_DIR=$PWD/manager npm --prefix clients/node test -- --runInBand
```

**Result: 48/48 passed**

All 48 tests pass. 3 `getLastUpdatedTimestamp` test cases removed. Regression guards (`not.toHaveProperty("last_updated_timestamp")`) retained and passing.

### Regression Guards Verified

Node tests confirmed `last_updated_timestamp` is absent from returned maps:
- `getRegions()` — `not.toHaveProperty("last_updated_timestamp")` ✓
- `getRegionKeys()` — `not.toContain("last_updated_timestamp")` ✓
- `getTenancies()` — `not.toHaveProperty("last_updated_timestamp")` ✓
- `getRealms()` — `not.toHaveProperty("last_updated_timestamp")` ✓
