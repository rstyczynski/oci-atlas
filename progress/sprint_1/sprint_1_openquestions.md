# Sprint 1 - More information needed

## Tenancy-scoped per-region attributes placement

Status: None

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

Answer: None

## Tenancy identifier key format

Status: None

Problem to clarify: The tenancy key in the schema must be stable and human-usable. Options are:
- Short name (e.g., `avq_prod`) — human-friendly, not globally unique
- Tenancy OCID (`ocid1.tenancy.oc1..aaa...`) — globally unique, long, opaque
- Both: short name as the map key, OCID as a field inside

What form should the tenancy key take?

Answer: None

## realms/v2 scope

Status: None

Problem to clarify: The current `realms/v1` schema appears complete and correct for realm-level physical attributes. Should this Sprint produce a `realms/v2` schema (even if structurally identical to v1), or should `realms/v1` remain unchanged and only `regions/v2` and `tenancies/v1` be new deliverables?

Answer: None
