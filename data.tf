# Data sources for Azure Stack HCI Migration module

# ========================================
# CORE DATA SOURCES
# ========================================

# Get existing Azure Migrate Project (for all modes)
data "azapi_resource" "migrate_project_existing" {
  count = !local.create_new_project && var.project_name != null ? 1 : 0

  name      = var.project_name
  parent_id = local.resource_group_id
  type      = "Microsoft.Migrate/migrateprojects@2020-06-01-preview"
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

  resource_id = try(data.azapi_resource.replication_solution[0].output.properties.details.extendedDetails.vaultId, "")
  type        = "Microsoft.DataReplication/replicationVaults@2024-09-01"
}

# Query replication fabrics
data "azapi_resource_list" "replication_fabrics" {
  count = local.is_initialize_mode ? 1 : 0

  parent_id = local.resource_group_id
  type      = "Microsoft.DataReplication/replicationFabrics@2024-09-01"

  depends_on = [azapi_resource.replication_vault]
}

# Query source fabric agents (DRAs) for role assignments
# Note: Uses has_fabric_inputs since resolved_fabric_id is computed at apply time
data "azapi_resource_list" "source_fabric_agents" {
  count = local.is_initialize_mode && local.has_fabric_inputs ? 1 : 0

  parent_id              = local.resolved_source_fabric_id
  type                   = "Microsoft.DataReplication/replicationFabrics/fabricAgents@2024-09-01"
  response_export_values = ["value"]

  depends_on = [data.azapi_resource_list.replication_fabrics]
}

# Query target fabric agents (DRAs) for role assignments
data "azapi_resource_list" "target_fabric_agents" {
  count = local.is_initialize_mode && local.has_fabric_inputs ? 1 : 0

  parent_id              = local.resolved_target_fabric_id
  type                   = "Microsoft.DataReplication/replicationFabrics/fabricAgents@2024-09-01"
  response_export_values = ["value"]

  depends_on = [data.azapi_resource_list.replication_fabrics]
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

# Validate the protected item exists and is ready for migration
data "azapi_resource" "protected_item_to_migrate" {
  count = local.is_migrate_mode ? 1 : 0

  resource_id = var.protected_item_id
  type        = "Microsoft.DataReplication/replicationVaults/protectedItems@2024-09-01"
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
