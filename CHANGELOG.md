# Changelog

All notable changes to this module are documented here.
This module is **preview** and follows [Semantic Versioning](https://semver.org/)
starting at `v0.x`; breaking changes are expected until `v1.0`.

## [Unreleased]

### Breaking changes

- **`var.location` is now optional and auto-discovered.** In every mode
  except `create-project`, the module reads the Azure region from the
  existing migrate project rather than requiring the caller to repeat it.
  This matches the `Az.Migrate` PowerShell behaviour, which never asks for a
  region when the project already exists. Callers that previously passed
  `location` can drop it (or leave it in — an explicit value still wins).
  When `create_migrate_project = true` and no project exists yet, the
  module surfaces a precondition error asking for `var.location`
  explicitly.

- **Variable surface reduced to match the `Az.Migrate` PowerShell cmdlet shape.**
  Sixteen flat variables were removed and replaced by two grouped optional
  objects plus internal auto-resolution. Consumers pinned to the previous
  version must update their inputs.

  Removed variables:
  - `instance_type` — now derived from `source_machine_type`
    (`"VMware"` → `"VMwareToAzStackHCI"`, `"HyperV"` → `"HyperVToAzStackHCI"`)
  - `policy_name`, `replication_extension_name` — auto-named from vault and fabric IDs
  - `source_fabric_agent_name`, `target_fabric_agent_name` — auto-discovered DRAs
  - `source_fabric_id`, `target_fabric_id` — auto-discovered from
    `source_appliance_name` / `target_appliance_name`, matching the
    `Initialize-AzMigrateLocalReplicationInfrastructure` PowerShell contract
    (the cmdlet does not accept fabric IDs)
  - `app_consistent_frequency_minutes`, `crash_consistent_frequency_minutes`,
    `recovery_point_history_minutes` — moved into `replication_policy`
  - `is_dynamic_memory_enabled`, `target_vm_cpu_cores`,
    `target_vm_ram_mb`, `source_vm_cpu_cores`, `source_vm_ram_mb` — moved into
    `target_vm_compute`
  - `hyperv_generation`, `target_test_virtual_switch_id`, and per-NIC
    `test_network_id` — removed; `hyperv_generation` is derived from the source
    VM boot type (VMware firmware UEFI → gen 2 / BIOS → gen 1, or the Hyper-V
    generation) and the test failover network always tracks the target network,
    both mirroring `New-AzMigrateLocalServerReplication`
  - `nic_id`, `os_disk_size_gb` — derived in simple-mode replication (NIC id read
    from the discovered machine, disk size derived from discovered disk)

  Added variables:
  - `replication_policy = object({ name, app_consistent_frequency_minutes,
    crash_consistent_frequency_minutes, recovery_point_history_minutes })`
    — all fields optional with sensible defaults.
  - `target_vm_compute = object({ cpu_cores, ram_mb, is_dynamic_memory_enabled })`
    — all fields optional with sensible defaults.

### Added

- **Appliance-registration discovery scaffold in `create-project` mode.** When
  creating a new project the module now also provisions a server discovery site
  (`Microsoft.OffAzure/ServerSites`, bound to the project's `ServerDiscovery`
  solution) and a master site (`Microsoft.OffAzure/MasterSites`, `allowMultipleSites`)
  in the project's resource group. An Azure Migrate appliance registers its
  per-appliance VMware/HyperV site under the master site; without this scaffold the
  project was created successfully but appliance registration failed later. Mirrors
  the portal's create-project flow (`CreateProjectHelper._getScopeBoundTemplates`).
  Adds outputs `master_site_id` and `discovery_server_site_id`.

- **Location auto-discovery.** New internal local `effective_location`
  resolves the deployment region in the following order:
  1. caller-supplied `var.location` (explicit override; required when
     creating a new migrate project),
  2. the existing migrate project's `location` (read via
     `data.azapi_resource.migrate_project_existing`),
  Resources that need a real region (`azapi_resource.migrate_project`,
  `replication_vault`, `cache_storage_account`, and `protected_item`'s
  `customLocationRegion`) reference `local.effective_location` instead of
  `var.location`. A lifecycle precondition on
  `azapi_resource.migrate_project` enforces an explicit value when the
  module is asked to create a new project.

- Fabric discovery is now active in `replicate` mode as well as `initialize`
  mode. Fabrics are resolved purely from `source_appliance_name` /
  `target_appliance_name`, matching the Az.Migrate PowerShell cmdlet
  `Initialize-AzMigrateLocalReplicationInfrastructure`, which never exposes
  fabric IDs to the caller.
- New internal locals (`effective_instance_type`, `effective_policy_name`,
  `effective_replication_extension_name`, `effective_source_fabric_agent_name`,
  `effective_target_fabric_agent_name`, `resolved_vault_id`,
  `needs_fabric_discovery`) handle resolution from the migrate project's
  Server Migration solution.
- `tags` and `diagnostic_settings` are now fully wired through the AVM
  interface — diagnostic settings produce one `azapi_resource` per map entry
  scoped to the replication vault, and `tags` propagate to the migrate
  project, replication vault, and cache storage account.

### Fixed

- **Cache storage account duplicate creation.** Initialize mode no longer
  creates a second storage account when the migrate project's Server
  Migration solution already records a `replicationStorageAccountId`. The
  module now respects the precedence: caller-supplied
  `cache_storage_account_id` ➔ solution-recorded ID ➔ create new.
- Example `examples/migrate/outputs.tf` and `examples/remove/outputs.tf`
  referenced module outputs that did not exist (`migration_job_id`,
  `protected_item_info`); corrected to existing outputs.
- `azapi_resource.diagnostic_setting` no longer fails with an
  apply-time-unknown `for_each` error; the resource now precondition-checks
  for a resolvable vault instead.
- **Brownfield role-assignment dedup on auto-discovered storage.**
  Re-running `initialize` against an already-initialized project produced
  six `RoleAssignmentExists` 409s when the cache storage account was
  auto-discovered from the migrate project's Server Migration solution
  (rather than supplied via `var.cache_storage_account_id`). The
  role-assignment lookup now fires in both paths and dedup keys are built
  from the correct storage account ID.
- **`runAsAccountId` is now auto-discovered for replicate mode.** Mirrors
  the Az CLI `azext_migrate.helpers.replication.new._process_inputs`
  behaviour: the module reads `machine.properties.vCenterId` (VMware) or
  `machine.properties.hostId` / `clusterId` (Hyper-V), then fetches the
  parent and lifts `properties.runAsAccountId`. Caller-supplied
  `var.run_as_account_id` still wins.
- **`customLocationRegion` is now auto-discovered from the customLocation
  resource itself.** Mirrors the Az CLI
  `helpers/replication/new/_execute_new.get_ARC_resource_bridge_info`
  behaviour: the protected item's `customLocationRegion` is now the region
  of the `Microsoft.ExtendedLocation/customLocations` resource (i.e. where
  the HCI cluster lives), not the migrate project's region. Without this,
  applying `replicate` against a cluster in a different region than the
  project produced `LocationNotAvailableForResourceType` on
  `Microsoft.AzureStackHCI/virtualHardDisks` several minutes into the
  apply. Falls back to the migrate project's region when no
  `custom_location_id` is supplied.
- **`migrate` mode now validates protected-item state at plan time.**
  Mirrors the Az CLI `validate_protected_item_for_migration`: the module
  refuses to call `/plannedFailover` unless `PlannedFailover` or `Restart`
  is in `properties.allowedJobs`. Surfaces a friendly error matching the
  CLI's wording instead of an opaque 400 several minutes into the apply.
- `azapi_resource.protected_item.targetArcClusterCustomLocationId` no
  longer fails `coalesce()` with a null `custom_location_id`; the
  expression now uses an explicit null-check.
- `examples/jobs/variables.tf` — `replication_vault_id` now defaults to
  `null` instead of a placeholder ARM ID. Without this fix, running the
  example without overriding the variable sent the placeholder string
  (`/subscriptions/00000000-.../replicationVaults/<vault>`) straight to
  ARM and produced a `SubscriptionNotFound` 404 instead of triggering the
  module's auto-discovery path.

### Documentation

- `examples/initialize` and `examples/replicate` are now bare-bones
  happy-path examples that mirror the PowerShell cmdlet shape exactly. All
  optional inputs were moved out of the example `main.tf` files and
  documented in each example's `_header.md` (regenerated into `README.md`).
- All example READMEs regenerated by `terraform-docs` to reflect the new
  variable surface.
- `var.run_as_account_id` description rewritten as a heredoc documenting
  the VMware and Hyper-V auto-discovery chains for parity with the
  PowerShell/CLI cmdlets.
