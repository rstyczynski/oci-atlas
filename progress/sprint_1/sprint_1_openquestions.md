# Sprint 1 - More information needed

## Tenancy-scoped per-region attributes placement

Status: Answered

Problem to clarify: Proxy, vault, toolchain.github, and observability.loki attributes belong to the intersection of tenancy × region (subscription). Two options:

Option A — Embed inside `tenancies/v1` as a region-keyed sub-map:
```
tenancies/v1:
  avq_prod:
    realm: oc1
    regions:
      ZRH:
        network.proxy: {...}
        security.vault: {...}
        toolchain.github: {...}
        observability: {...}
```

Option B — Separate `subscriptions/v1` domain (junction table):
```
subscriptions/v1:
  avq_prod_ZRH:
    tenancy: avq_prod
    region: ZRH
    network.proxy: {...}
    security.vault: {...}
    ...
```

Answer: Option A, but modified

1. region code instead if key
2. network private addresses are here, as are per tenancy

```
tenancies/v1:
  avq_prod:
    realm: oc1
    regions:
      eu-zurich-1:
        network.private: {...}
        network.proxy: {...}
        security.vault: {...}
        toolchain.github: {...}
        observability: {...}
```

## Tenancy identifier key format

Status: Answered

Problem to clarify: The tenancy key in the schema must be stable and human-usable. Options are:
- Short name (e.g., `avq_prod`) — human-friendly, not globally unique
- Tenancy OCID (`ocid1.tenancy.oc1..aaa...`) — globally unique, long, opaque
- Both: short name as the map key, OCID as a field inside

What form should the tenancy key take?

Answer: Short name

## realms/v2 scope

Status: Answered

Problem to clarify: The current `realms/v1` schema appears complete and correct for realm-level physical attributes. Should this Sprint produce a `realms/v2` schema (even if structurally identical to v1), or should `realms/v1` remain unchanged and only `regions/v2` and `tenancies/v1` be new deliverables?

Answer: `realms/v1`, `regions/v2`, `tenancies/v1`

## prometheus_scraping_cidr ownership

Status: Answered

Problem to clarify: In `regions_v1`, the `observability` group contains three fields:

- `prometheus_scraping_cidr` — a CIDR range used for Prometheus scraping
- `loki_destination_cidr` — Loki destination CIDR
- `loki_fqdn` — Loki fully-qualified domain name

The loki fields are clearly tenancy-specific. For `prometheus_scraping_cidr`: it represents the CIDR from which Prometheus scrapes targets. Is this a physical region attribute (same for all tenancies in a region, i.e., belongs in `regions/v2`) or a tenancy-specific attribute (each tenancy has its own Prometheus scraping range, i.e., belongs in `tenancies/v1`)?

Answer: All `observability` goes to tenancy data.
