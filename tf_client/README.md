# tf_client — Terraform module for reading the global directory

Fetches `regions/v1` from an OCI Object Storage bucket using `data "oci_objectstorage_object"` and exposes the parsed region data as outputs. No scripts.

## Schema versioning

The module is split into two layers:

- **`tf_client`** (core) — auth, namespace resolution, region discovery from bucket OCID. Schema-independent. Outputs `namespace`, `bucket_name`, and `region_key`.
- **`tf_client/gdir_regions_v1`** (v1 regions) — fetches its own object (`regions/v1`), parses the raw JSON, and exposes outputs tied to the v1 regions schema. Add `tf_client/gdir_services_v1` or `tf_client/gdir_regions_v2` when the scope or schema changes.

Consumers call both modules and wire `namespace`, `bucket_name`, and `region_key` from core into the DAL.

## Inputs

| Name | Description | Default |
|------|-------------|--------|
| `compartment_id` | OCID of the compartment (used to resolve the namespace) | required |
| `bucket_name` | Object Storage bucket name | `"info"` |
| `object_name` | Object name inside the bucket | `"v1/regions"` |
| `region_key` | Region key for single-region outputs (e.g. `region11`, `eu-region1`) | `"region11"` |

## Outputs

| Name | Description |
|------|-------------|
| `regions` | All regions (map of region_key → { realm, proxy: { url, ip, port } }) |
| `region_keys` | List of all region keys |
| `region` | Single region object for `region_key` |
| `region_proxy` | Proxy object for that region (url, ip, port) |
| `region_proxy_ip` | Proxy IP for that region |
| `region_proxy_port` | Proxy port for that region |
| `region_realm` | Realm for that region |

## Example

See `examples/client`:

```bash
cd examples/client
cp terraform.tfvars.example terraform.tfvars   # set compartment_id
terraform init
terraform apply -auto-approve
terraform output
```
