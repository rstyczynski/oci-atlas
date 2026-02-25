# Sprint 1 - Feedback

## GD-2. DAL for tenancies/v1 with dependency on regions/v2

Status: None

The v2 data model introduces a two-domain lookup (physical region from `regions/v2`, tenancy-specific attributes from `tenancies/v1`). A unified wrapper DAL is not required. It is sufficient that the `gdir_tenancies_v1` DAL is aware of its dependency on `regions/v2`. May use region DAL or read from it directly when needed (without delegating to a separate `gdir_regions_v2` DAL layer). To be decided later.

Key design points:

1. **Tenancy name is auto-discovered** — resolved from the OCI SDK (tenancy OCID available in the active OCI connection context), not provided manually by the caller.
2. **No unified wrapper required** — `gdir_tenancies_v1` fetches both `tenancies/v1` and `regions/v2` objects directly as needed. Callers use `gdir_tenancies_v1` for all v2 queries; no separate aggregation layer needed.
3. **Region auto-discovery unchanged** — region key continues to be resolved from the bucket OCID as per existing pattern.

Additionally, cross-document referential integrity validation (tenancy region keys must exist in `regions/v2`) should be added to the `tf_manager/validate.sh` toolchain.
