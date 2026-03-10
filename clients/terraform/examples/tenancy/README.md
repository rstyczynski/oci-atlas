# Tenancy example

Reads `tenancies/v1` from the bucket and outputs the tenancy and region-scoped data for the resolved tenancy and region.

## Why outputs can be null

With default `tenancy_key = null` and `region_key = null`, the module **discovers** them from OCI:

- **Tenancy key** = IAM tenancy name (from `oci os ns get-metadata` → `oci iam tenancy get`).
- **Region key** = 4th segment of the bucket OCID.

If the discovered tenancy name is **not** a key in the `tenancies/v1` JSON in the bucket (e.g. your real tenancy is `avq3` but the bucket only has `demo_corp`, `acme_prod`), then `tenancy` is null and all downstream outputs are null. If the discovered region is not in that tenancy’s `regions`, `tenancy_region` is null.

## What to do

1. **See what was used** — run `terraform output tenancy_key` and `terraform output region_key`. If they are set but other outputs are null, that tenancy or region is not in the bucket data.
2. **Use keys that exist in your data** — e.g. for demo data in the repo, set:
   ```bash
   export TF_VAR_tenancy_key=demo_corp
   export TF_VAR_region_key=tst-region-1
   terraform apply -auto-approve
   terraform output
   ```
3. **Ensure bucket data** — the bucket’s `tenancies/v1` object must contain an entry for your tenancy key and that entry must have the chosen region in `regions`. Use `tf_manager` to upload `tenancies_v1.json` (or `tenancies_v1.demo.json`) so the keys you use exist.
