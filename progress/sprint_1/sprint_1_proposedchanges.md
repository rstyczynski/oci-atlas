# Sprint 1 - Feedback

## GD-2. Unified DAL v2 for regions/v2 and tenancies/v1

Status: None

The v2 data model introduces a two-domain lookup (physical region from `regions/v2`, tenancy-specific attributes from `tenancies/v1`). The existing DAL clients (Node.js, CLI, Terraform) each implement a single-domain fetch pattern and are unaware of tenancy identity.

A new unified DAL is needed that:

1. Accepts tenancy short name as input (via config, env var, or resolved from OCI SDK tenancy OCID)
2. Auto-discovers region from OCI SDK (existing behaviour)
3. Fetches both `regions/v2` and `tenancies/v1` internally
4. Exposes a single interface where callers get proxy, public CIDRs, vault, toolchain, and observability without knowing which domain each field comes from

This DAL should be implemented in all three client types following the existing `gdir_<domain>_<version>` naming convention, for example `gdir_v2` as an aggregating layer over `gdir_regions_v2` and `gdir_tenancies_v1`.

Additionally, cross-document referential integrity validation (tenancy region keys must exist in `regions/v2`) should be added to the `tf_manager/validate.sh` toolchain.
