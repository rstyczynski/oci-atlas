# Sprint 5 - Implementation Notes

Status: tested

## GD-5. Tenancy key is auto-discovered

### Implementation Summary

Implemented tenancy key auto-discovery for tenant-focused clients with explicit override support.

- CLI (`cli_client`):
  - `gdir_tenancies_v1.sh` now resolves `TENANCY_KEY` automatically when unset:
    1. derives tenancy OCID from `oci os ns get-metadata --query 'data."default-s3-compartment-id"' --raw-output`
    2. resolves tenancy name via `oci iam tenancy get --tenancy-id <ocid> --query 'data.name' --raw-output`
    3. validates that derived key exists in `tenancies/v1` data
  - `examples/tenancy.sh` updated so `TENANCY_KEY` is optional.

- Node (`node_client`):
  - `gdir_tenancies_v1.ts` updated to auto-resolve tenancy key when `tenancyKey` is not provided.
  - Added IAM dependency (`oci-identity`) and key validation against loaded `tenancies/v1` map.
  - Explicit `TENANCY_KEY` still overrides discovery.

- Terraform (`tf_client/gdir_tenancies_v1`):
  - Added discovery flow:
    - `external` data source gets tenancy OCID from namespace metadata.
    - `oci_identity_tenancy` maps OCID to tenancy name (used as discovered `tenancy_key`).
  - `var.tenancy_key` remains explicit override.
  - `tf_client/examples/tenancy/variables.tf` defaults changed to discovery mode (`null`).

- Data update:
  - Added `avq3` tenancy to `tf_manager/tenancies_v1.json` so discovered key from active OCI connection exists in the dataset.

### Files Updated

- `cli_client/gdir_tenancies_v1.sh`
- `cli_client/examples/tenancy.sh`
- `node_client/src/gdir_tenancies_v1.ts`
- `node_client/package.json`
- `tf_client/gdir_tenancies_v1/main.tf`
- `tf_client/examples/tenancy/variables.tf`
- `tf_manager/tenancies_v1.json`
- `README.md` (examples and behavior notes aligned with tenancy-key discovery)
- `BACKLOG.md`, `PLAN.md` (wording corrected to tenancy key discovery)

### Known Constraints

- Discovery depends on OCI CLI/SDK permissions for namespace metadata and IAM tenancy read operations.
- Derived tenancy key must exist as a top-level key in `tenancies/v1` data, otherwise explicit `TENANCY_KEY` is required.

