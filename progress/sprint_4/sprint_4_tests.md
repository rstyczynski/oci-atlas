# Sprint 4 - Tests

Status: In Progress

## Executed
- Node Jest: `npm --prefix node_client test -- --runInBand` — PASS (51 tests)
- Bash CLI: `TEST_DATA_DIR=$PWD/tf_manager bash cli_client/test/run_tests.sh` — PASS (all checks)

## Pending
- AJV schema compile: `npx ajv-cli@5 compile --spec=draft2020 -s realms_v1.schema.json -s regions_v2.schema.json -s tenancies_v1.schema.json` (timed out during npx download; rerun after install)
- Terraform validate: `terraform -chdir=tf_client/examples/region validate` and `terraform -chdir=tf_client/examples/regions validate` — init blocked by offline provider registry access in sandbox

## Data Points
- regions_v2.json schema_version: 1.0.0
- tenancies_v1.json schema_version: 1.0.0
- realms_v1.json schema_version: 1.0.0, last_updated_timestamp: 2026-02-25T12:00:00Z
