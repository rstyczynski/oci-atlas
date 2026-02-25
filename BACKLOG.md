# OCI Atlas - Global Directory

version: 1

Global Directory is a centralized catalog system for Oracle Cloud Infrastructure (OCI) metadata — region attributes (network, proxy, vault, toolchain, observability) and realm information. It stores JSON data in OCI Object Storage with schema validation, versioning by domain, and provides typed client libraries for Node.js, CLI (Bash), and Terraform to read the data.

## Backlog

Project aim is to deliver all the features listed in a below Backlog. Backlog Items selected for implementation are added to iterations detailed in `PLAN.md`. Full list of Backlog Items presents general direction and aim for this project.

### GD-1. Build foundation data model

The region properties are strictly related to a tenancy for private attributes, and to physical region for physical attributes as e.g. public CIDRs. Both are associated to realm. Single region belongs to a single realm. The same with Tenancy. The tenancy may be subscribed to multiple realms.

                    +----------------------+
                    |         REALM        |
                    +----------------------+
                      1 |               | 1
                        |               |
                        v               v
                 +------------+   +------------+
                 |   REGION   |   |  TENANCY   |
                 +------------+   +------------+
                      ^                 ^
                      |                 |
                      +------- M:N -----+
                          subscription

Currently realm_v1 describes a realm, and region_v1 as is described combined single tenancy from region point of view.

The goal for a data model is to simplify runtime side scripts and programs' in environment discovery under defined OCI security context a.k.a connection.

This task defines data model for realm, region, and tenancy to be used by clients to discover for current region:
1. proxy URL
2. proxy IP, port
3. prometheus attributes for current region
4. github attributes for current region

Note that region_v1 data set combines real regions and tenancies, what should be divided into proper data domains.

Product of this task is to produce data model v2 reflecting tuple: realm, region, tenancy. It's just a model w/o provisioning add w/o DAL.
