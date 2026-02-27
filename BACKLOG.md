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

### GD-1-fix1. Remove `realm` attribute from tenancies json data file

### GD-2. Establish versioning strategy for data and access layer

Data and code is tracked by a [semantic versioning](https://semver.org) e.g. 1.5.12

MAJOR - indicating breaking change. Previous version cannot use current version data or logic
MINOR - indicating new feature. Previous version may use current version w/o access to new features
PATCH - bug fix adjusting data / code to state required by given MAJOR.MINOR

Areas for analysis:

1.Object Storage

* clients in given version have access to their data in the bucket
* MAJOR versions are under ${data}/${MAJOR} directory
* MINOR are indicated by filename i.e. ${data}/${MAJOR}/${data}-${MAJOR}.${MINOR}.json. Latest MINOR is always accessible via ${data}/${MAJOR}/${data}-latest.json
* PATCH is just applied to data files - version here is tracked by object storage versioning for historical purposes

2.Data Access Layer

Code version is described in dependency description or other way defined by DAL technology and installed. DAL code is bound to a MAJOR.MINOR version, thus data version is hardcoded.

### GD-3. tf_manager handles upload of latest version of a data file to the bucket
