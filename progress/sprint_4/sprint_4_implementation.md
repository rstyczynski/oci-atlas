# Sprint 4 - Implementation Notes

Status: under_construction

## GD-4. Apply versioning strategy for data and access layer

### Implementation Summary
- Added mandatory `schema_version` to all active schemas/data; added `last_updated_timestamp` to realms_v1.json.
- Removed regions_v1 artefacts (data/schema/DAL/CLI/TF).
- Added new DALs for regions_v2 and tenancies_v1 in Node, Bash, and Terraform; updated exports and examples accordingly.
- Added npm `prepare` script and refreshed TypeScript examples to new DAL surface.

### Code Artifacts
- node_client/src: gdir_regions_v2.ts, gdir_tenancies_v1.ts, gdir_realms_v1.ts (metadata update), index.ts, types.ts
- cli_client: gdir_regions_v2.sh, gdir_tenancies_v1.sh, gdir_realms_v1.sh (metadata update), examples/region.sh, examples/regions.sh, test/run_tests.sh
- tf_manager: regions_v2.tf, tenancies_v1.tf, updated JSON + schemas; removed regions_v1 files
- tf_client: gdir_regions_v2 module, gdir_tenancies_v1 module, updated examples/region and examples/regions

### Testing Results
- Node: `npm --prefix node_client test -- --runInBand` (pass)
- Bash: `TEST_DATA_DIR=$PWD/tf_manager bash cli_client/test/run_tests.sh` (pass)
- Terraform: validate pending `terraform init` (modules added; not yet initialized)
- ajv: `npx ajv-cli@5 compile ...` attempted (timeout; needs rerun after caching)

### Known Issues / Follow-ups
- Run `terraform init` then `terraform validate` for tf_client/examples/* to complete TF checks.
- Rerun `npx ajv-cli@5 compile ...` with cache or local install to record PASS.

### User Documentation
- See updated CLI examples (`cli_client/examples/region.sh`, `cli_client/examples/regions.sh`).
- Node examples updated: `npm run example:region`, `npm run example:regions`, `npm run example:realm`.
