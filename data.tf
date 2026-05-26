# Data sources for Azure Stack HCI Migration module

# ========================================
# CORE DATA SOURCES
# ========================================

# Get existing Azure Migrate Project (for all modes)
data "azapi_resource" "migrate_project_existing" {
  count = !local.create_new_project && var.project_name != null ? 1 : 0

  name                   = var.project_name
  parent_id              = local.resource_group_id
  type                   = "Microsoft.Migrate/migrateprojects@2020-06-01-preview"
  response_export_values = ["location"]
}

# Get Data Replication Solution
data "azapi_resource" "replication_solution" {
  count = (local.is_initialize_mode || local.is_replicate_mode || local.is_list_mode || local.is_get_mode || local.is_jobs_mode) && var.project_name != null ? 1 : 0

  name                   = "Servers-Migration-ServerMigration_DataReplication"
  parent_id              = local.migrate_project_id
  type                   = "Microsoft.Migrate/migrateprojects/solutions@2020-06-01-preview"
  response_export_values = ["properties.details.extendedDetails"]
}

# ========================================
# DISCOVER MODE DATA SOURCES
# ========================================

# Query discovered servers from VMware or HyperV sites
data "azapi_resource_list" "discovered_servers" {
  count = local.is_discover_mode ? 1 : 0

  parent_id = var.appliance_name != null ? "${local.resource_group_id}/providers/Microsoft.OffAzure/${var.source_machine_type == "HyperV" ? "HyperVSites" : "VMwareSites"}/${var.appliance_name}" : local.migrate_project_id
  type      = var.appliance_name != null ? (var.source_machine_type == "HyperV" ? "Microsoft.OffAzure/HyperVSites/machines@2023-06-06" : "Microsoft.OffAzure/VMwareSites/machines@2023-06-06") : "Microsoft.Migrate/migrateprojects/machines@2020-05-01"
}

# ========================================
# INITIALIZE MODE DATA SOURCES
# ========================================

# Get existing replication vault (from solution)
data "azapi_resource" "replication_vault" {
  count = local.vault_exists_in_solution ? 1 : 0

  resource_id            = try(data.azapi_resource.replication_solution[0].output.properties.details.extendedDetails.vaultId, "")
  type                   = "Microsoft.DataReplication/replicationVaults@2024-09-01"
  response_export_values = ["identity"]
}

# ========================================
# BROWNFIELD DETECTION DATA SOURCES
# ========================================

# List existing role assignments on cache storage account (brownfield support).
# Triggered when the cache storage account is already pre-existing — either supplied
# explicitly via var.cache_storage_account_id, or auto-discovered from the migrate
# project's replication solution (replicationStorageAccountId on the solution).
# Without this, re-running initialize against an already-initialized project hits
# RoleAssignmentExists 409s because the dedup guards have nothing to compare against.
data "azapi_resource_list" "cache_storage_role_assignments" {
  count = local.is_initialize_mode && (var.cache_storage_account_id != null || local.has_existing_replication_storage_account) ? 1 : 0

  parent_id              = coalesce(var.cache_storage_account_id, local.existing_replication_storage_account_id)
  type                   = "Microsoft.Authorization/roleAssignments@2022-04-01"
  response_export_values = ["value"]
}

# List existing replication policies in the vault (brownfield support)
data "azapi_resource_list" "existing_policies" {
  count = local.is_initialize_mode && local.vault_exists_in_solution ? 1 : 0

  parent_id              = data.azapi_resource.replication_vault[0].id
  type                   = "Microsoft.DataReplication/replicationVaults/replicationPolicies@2024-09-01"
  response_export_values = ["value"]
}

# List existing replication extensions in the vault (brownfield support)
data "azapi_resource_list" "existing_extensions" {
  count = local.is_initialize_mode && local.vault_exists_in_solution && local.has_fabric_inputs ? 1 : 0

  parent_id              = data.azapi_resource.replication_vault[0].id
  type                   = "Microsoft.DataReplication/replicationVaults/replicationExtensions@2024-09-01"
  response_export_values = ["value"]
}

# Query replication fabrics
# depends_on is intentional: when a new vault is being created in this plan,
# we want the fabric list read deferred until apply so that the discovered_*
# locals (and the resolved_source/target_fabric_id values derived from them)
# resolve against a stable fabric set instead of an empty plan-time read.
data "azapi_resource_list" "replication_fabrics" {
  count = local.needs_fabric_discovery ? 1 : 0

  parent_id = local.resource_group_id
  type      = "Microsoft.DataReplication/replicationFabrics@2024-09-01"

  depends_on = [azapi_resource.replication_vault]
}

# Query source fabric agents (DRAs) for role assignments and name lookup.
# Fires in both initialize (to grant RBAC) and replicate (to look up agent names).
data "azapi_resource_list" "source_fabric_agents" {
  count = local.needs_fabric_discovery && local.has_fabric_inputs ? 1 : 0

  parent_id              = local.resolved_source_fabric_id
  type                   = "Microsoft.DataReplication/replicationFabrics/fabricAgents@2024-09-01"
  response_export_values = ["value"]

  depends_on = [data.azapi_resource_list.replication_fabrics]
}

# Query target fabric agents (DRAs) for role assignments and name lookup
data "azapi_resource_list" "target_fabric_agents" {
  count = local.needs_fabric_discovery && local.has_fabric_inputs ? 1 : 0

  parent_id              = local.resolved_target_fabric_id
  type                   = "Microsoft.DataReplication/replicationFabrics/fabricAgents@2024-09-01"
  response_export_values = ["value"]

  depends_on = [data.azapi_resource_list.replication_fabrics]
}

# ========================================
# RUN-AS ACCOUNT AUTO-DISCOVERY (replicate)
# ========================================
# Mirrors Az CLI `azext_migrate.helpers.replication.new._process_inputs`:
#   VMware: machine.properties.vCenterId  -> GET vCenter  -> properties.runAsAccountId
#   Hyper-V (standalone): machine.properties.hostId    -> GET host    -> properties.runAsAccountId
#   Hyper-V (clustered):  machine.properties.clusterId -> GET cluster -> properties.runAsAccountId
# Caller can still override via var.run_as_account_id.
data "azapi_resource" "replicate_machine" {
  count = local.is_replicate_mode && var.run_as_account_id == null && var.machine_id != null ? 1 : 0

  resource_id            = var.machine_id
  type                   = local.effective_instance_type == "VMwareToAzStackHCI" ? "Microsoft.OffAzure/VMwareSites/machines@2023-06-06" : "Microsoft.OffAzure/HyperVSites/machines@2023-06-06"
  response_export_values = ["properties.vCenterId", "properties.hostId", "properties.clusterId"]
}

data "azapi_resource" "machine_parent_for_run_as" {
  count = local.is_replicate_mode && var.run_as_account_id == null && var.machine_id != null && local.machine_parent_id != null ? 1 : 0

  resource_id            = local.machine_parent_id
  type                   = local.machine_parent_type
  response_export_values = ["properties.runAsAccountId"]
}

# ========================================
# CUSTOM LOCATION REGION AUTO-DISCOVERY (replicate)
# ========================================
# Mirrors Az CLI `azext_migrate.helpers.replication.new._execute_new.get_ARC_resource_bridge_info`:
# the protected item's `customLocationRegion` must be the actual region of the
# customLocation resource (i.e. where the HCI cluster lives), NOT the migrate
# project's region. virtualHardDisks are provisioned in `customLocationRegion`,
# so a mismatch produces a `LocationNotAvailableForResourceType` failure when
# the cluster is in a different region than the project.
data "azapi_resource" "custom_location" {
  count = local.is_replicate_mode && var.custom_location_id != null ? 1 : 0

  resource_id            = var.custom_location_id
  type                   = "Microsoft.ExtendedLocation/customLocations@2021-08-15"
  response_export_values = ["location"]
}

# ========================================
# JOBS MODE DATA SOURCES
# ========================================

# Get vault from solution (for jobs mode)
data "azapi_resource" "vault_for_jobs" {
  count = local.is_jobs_mode ? 1 : 0

  resource_id = try(data.azapi_resource.replication_solution[0].output.properties.details.extendedDetails.vaultId, var.replication_vault_id)
  type        = "Microsoft.DataReplication/replicationVaults@2024-09-01"
}

# Get a specific job by name
data "azapi_resource" "replication_job" {
  count = local.is_jobs_mode && var.job_name != null ? 1 : 0

  name      = var.job_name
  parent_id = var.replication_vault_id != null ? var.replication_vault_id : data.azapi_resource.vault_for_jobs[0].id
  type      = "Microsoft.DataReplication/replicationVaults/jobs@2024-09-01"
}

# List all jobs in the vault
data "azapi_resource_list" "replication_jobs" {
  count = local.is_jobs_mode && var.job_name == null ? 1 : 0

  parent_id = var.replication_vault_id != null ? var.replication_vault_id : data.azapi_resource.vault_for_jobs[0].id
  type      = "Microsoft.DataReplication/replicationVaults/jobs@2024-09-01"
}

# ========================================
# GET MODE DATA SOURCES
# ========================================

# Get vault from solution (for get mode when using name lookup)
data "azapi_resource" "vault_for_get" {
  count = local.is_get_mode && var.protected_item_id == null ? 1 : 0

  resource_id = try(data.azapi_resource.replication_solution[0].output.properties.details.extendedDetails.vaultId, var.replication_vault_id)
  type        = "Microsoft.DataReplication/replicationVaults@2024-09-01"
}

# Get protected item by full resource ID
data "azapi_resource" "protected_item_by_id" {
  count = local.is_get_mode && var.protected_item_id != null ? 1 : 0

  resource_id            = var.protected_item_id
  type                   = "Microsoft.DataReplication/replicationVaults/protectedItems@2024-09-01"
  response_export_values = ["*"]
}

# Get protected item by name (requires project/vault lookup)
data "azapi_resource" "protected_item_by_name" {
  count = local.is_get_mode && var.protected_item_id == null && var.protected_item_name != null ? 1 : 0

  name                   = var.protected_item_name
  parent_id              = var.replication_vault_id != null ? var.replication_vault_id : data.azapi_resource.vault_for_get[0].id
  type                   = "Microsoft.DataReplication/replicationVaults/protectedItems@2024-09-01"
  response_export_values = ["*"]
}

# ========================================
# LIST MODE DATA SOURCES
# ========================================

# Get vault from solution (for list mode)
data "azapi_resource" "vault_for_list" {
  count = local.is_list_mode ? 1 : 0

  resource_id = try(data.azapi_resource.replication_solution[0].output.properties.details.extendedDetails.vaultId, var.replication_vault_id)
  type        = "Microsoft.DataReplication/replicationVaults@2024-09-01"
}

# List all protected items in the vault
data "azapi_resource_list" "protected_items" {
  count = local.is_list_mode ? 1 : 0

  parent_id = var.replication_vault_id != null ? var.replication_vault_id : data.azapi_resource.vault_for_list[0].id
  type      = "Microsoft.DataReplication/replicationVaults/protectedItems@2024-09-01"
}

# ========================================
# MIGRATE MODE DATA SOURCES
# ========================================

# Validate the protected item exists and is ready for migration.
# response_export_values surface allowedJobs + protectionState so the planned_failover
# resources can run a CLI-parity precondition (mirrors the Az CLI's
# `validate_protected_item_for_migration` in helpers/migration/start/_validate.py).
data "azapi_resource" "protected_item_to_migrate" {
  count = local.is_migrate_mode ? 1 : 0

  resource_id            = var.protected_item_id
  type                   = "Microsoft.DataReplication/replicationVaults/protectedItems@2024-09-01"
  response_export_values = ["properties.allowedJobs", "properties.protectionState", "properties.protectionStateDescription"]
}

# ========================================
# REMOVE MODE DATA SOURCES
# ========================================

# Get vault from solution (for remove mode)
data "azapi_resource" "protected_item_to_remove" {
  count = local.is_remove_mode ? 1 : 0

  resource_id = var.target_object_id
  type        = "Microsoft.DataReplication/replicationVaults/protectedItems@2024-09-01"
}
