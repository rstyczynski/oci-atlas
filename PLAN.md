# Development plan

Global Directory is a centralized catalog system for Oracle Cloud Infrastructure (OCI) metadata. Provides typed client libraries (Node.js, Bash/CLI, Terraform) backed by schema-validated JSON in OCI Object Storage.

Instruction for the operator: keep the development sprint by sprint by changing `Status` label from Planned via Progress to Done. To achieve simplicity each iteration contains exactly one feature. You may add more backlog Items in `BACKLOG.md` file, referencing them in this plan.

Instruction for the implementor: keep analysis, design and implementation as simple as possible to achieve goals presented as Backlog Items. Remove each not required feature sticking to the Backlog Items definitions.

## Sprint 1 - Foundation Data Model

Status: Done
Mode: managed

Backlog Items:

* GD-1. Build foundation data model

## Sprint 2 - sprint 1 bug fix

Status: Rejected
Mode: managed

Backlog Items:

* GD-1-fix1. Remove `realm` attribute from tenancies json data file

## Sprint 3 - Establish versioning strategy for data and access layer

Status: Done
Mode: managed

Backlog Items:

* GD-2. Establish versioning strategy for data and access layer

## Sprint 4 - Apply versioning strategy for data and access layer

Status: Done
Mode: managed

Backlog Items:

* GD-4. Apply versioning strategy for data and access layer as documented in VERSIONING.md (Sprint 3 product)

## Sprint 5 - Tenancy key is auto-discovered

Status: Done
Mode: managed

Backlog Items:

* GD-5. Tenancy key is auto-discovered

## Sprint 6 - Synthetic data sets review

Status: Fixed
Mode: managed

Backlog Items:

* GD-6. Synthetic data sets review

Bug fixes:

* GD-6-1. make sure all synthetic OCID follows Oracle' pattern. Fields and field lengths should be as for regular keys.
* GD-6-2. make sure private network CIDR are belongs to CIDR reserved for the tenancy
* GD-6-3. make sure all regions for demo tenancy belongs to given realm. REalm may be synthetic, but when used the real one - region should be existing ones. Prefer using real exiting realms / regions.
* GD-6-4. I do not see demo_mapping.sh to be used in exemplary code. Should come before autodiscovery tenancy
* GD-6-5. demo_mapping.sh must auto discover active tenancy key, realm and at least home region.*  Move demo_mapping.sh to bin directory.
* GD-6-6. demo_mapping.sh must inject data into the bucket to make data available for shell, node, and terraform clients. tf_manager must have not git traceable file source used to sync with bucket. This file is build by demo_mapping.sh (demo mode) or copy real source if not in demo mode. demo_mapping.sh is a part of tf_manager. Visible information about mapping of synthetic data to a bucket one is presented when working in this mode.
* GD-6-7. demo_mapping.sh must retain demo_corp tenancy information. acme_corp is mapped to current live tenancy in demo mode, and demo_corp must be available in data source.
* GD-6-8. (done manually) demo_corp must define more than one region. Add one more region to demo dataset. demo_corp use test synthetic regions.

## Sprint 7 - Restructure directories

Status: Progress
Mode: YOLO

Backlog Items:

* GD-10. Restructure client directories

<!-- TODO: Define your Sprints below. Each Sprint references Backlog Items from BACKLOG.md. Example format:

## Sprint 1 - <Sprint Name>

Status: Planned
Mode: managed

Backlog Items:

* GD-1. Title of backlog item

## Sprint 2 - <Sprint Name>

Status: Planned
Mode: YOLO
Speed: FAST

Backlog Items:

* GD-2. Title of second item

-->
