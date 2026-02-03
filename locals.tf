# Local values for Azure Stack HCI Migration module

locals {
  # ========================================
  # PROJECT
  # ========================================
  # Create new Migrate project if project_name is provided and create_migrate_project is true
  create_new_project = var.create_migrate_project && var.project_name != null
  # Only create new vault if in initialize mode and vault doesn't exist
  create_new_vault = local.is_initialize_mode && !local.vault_exists_in_solution
  # Auto-discover source fabric from appliance name
  # Finds fabric where: name starts with/contains appliance_name AND instanceType matches AND provisioningState is Succeeded
  discovered_source_fabric = local.is_initialize_mode && var.source_appliance_name != null && var.source_fabric_id == null && length(data.azapi_resource_list.replication_fabrics) > 0 ? try(
    [for fabric in data.azapi_resource_list.replication_fabrics[0].output.value :
      fabric if(
        try(fabric.properties.provisioningState, "") == "Succeeded" &&
        try(fabric.properties.customProperties.instanceType, "") == local.source_fabric_instance_type &&
        (
          lower(try(fabric.name, "")) == lower(var.source_appliance_name) ||
          startswith(lower(try(fabric.name, "")), lower(var.source_appliance_name)) ||
          contains(lower(try(fabric.name, "")), lower(var.source_appliance_name))
        )
      )
    ][0],
    null
  ) : null
  # Auto-discover target fabric from appliance name
  discovered_target_fabric = local.is_initialize_mode && var.target_appliance_name != null && var.target_fabric_id == null && length(data.azapi_resource_list.replication_fabrics) > 0 ? try(
    [for fabric in data.azapi_resource_list.replication_fabrics[0].output.value :
      fabric if(
        try(fabric.properties.provisioningState, "") == "Succeeded" &&
        try(fabric.properties.customProperties.instanceType, "") == local.target_fabric_instance_type &&
        (
          lower(try(fabric.name, "")) == lower(var.target_appliance_name) ||
          startswith(lower(try(fabric.name, "")), lower(var.target_appliance_name)) ||
          contains(lower(try(fabric.name, "")), lower(var.target_appliance_name))
        )
      )
    ][0],
    null
  ) : null
  # Determine if we have fabric configuration inputs (used for count - must be known at plan time)
  # These check if the user provided either explicit IDs or appliance names for discovery
  has_fabric_inputs = (var.source_fabric_id != null || var.source_appliance_name != null) && (var.target_fabric_id != null || var.target_appliance_name != null)
  # ========================================
  # OPERATION MODE FLAGS
  # ========================================
  # tflint-ignore: terraform_unused_declarations
  is_create_project_mode = var.operation_mode == "create-project"
  is_discover_mode       = var.operation_mode == "discover"
  is_get_mode            = var.operation_mode == "get"
  is_initialize_mode     = var.operation_mode == "initialize"
  is_jobs_mode           = var.operation_mode == "jobs"
  is_list_mode           = var.operation_mode == "list"
  is_migrate_mode        = var.operation_mode == "migrate"
  is_remove_mode         = var.operation_mode == "remove"
  is_replicate_mode      = var.operation_mode == "replicate"
  # ========================================
  # AVM REQUIRED LOCALS
  # ========================================
  # tflint-ignore: terraform_unused_declarations
  managed_identities = {
    system_assigned_user_assigned = (var.managed_identities.system_assigned || length(var.managed_identities.user_assigned_resource_ids) > 0) ? {
      this = {
        type                       = var.managed_identities.system_assigned && length(var.managed_identities.user_assigned_resource_ids) > 0 ? "SystemAssigned, UserAssigned" : length(var.managed_identities.user_assigned_resource_ids) > 0 ? "UserAssigned" : "SystemAssigned"
        user_assigned_resource_ids = var.managed_identities.user_assigned_resource_ids
      }
    } : {}
    system_assigned = var.managed_identities.system_assigned ? {
      this = {
        type = "SystemAssigned"
      }
    } : {}
    user_assigned = length(var.managed_identities.user_assigned_resource_ids) > 0 ? {
      this = {
        type                       = "UserAssigned"
        user_assigned_resource_ids = var.managed_identities.user_assigned_resource_ids
      }
    } : {}
  }
  # Resolved Migrate project ID (created or existing)
  migrate_project_id = local.create_new_project ? azapi_resource.migrate_project[0].id : (
    length(data.azapi_resource.migrate_project_existing) > 0 ? data.azapi_resource.migrate_project_existing[0].id : null
  )
  # ========================================
  # SUBSCRIPTION & RESOURCE GROUP
  # ========================================
  # Parse subscription_id from parent_id (the resource group ID)
  parsed_parent_id = provider::azapi::parse_resource_id("Microsoft.Resources/resourceGroups", var.parent_id)
  # Resolve fabric IDs: priority order is explicit ID > auto-discovered from appliance name
  resolved_source_fabric_id = var.source_fabric_id != null ? var.source_fabric_id : (
    local.discovered_source_fabric != null ? try(local.discovered_source_fabric.id, null) : null
  )
  resolved_target_fabric_id = var.target_fabric_id != null ? var.target_fabric_id : (
    local.discovered_target_fabric != null ? try(local.discovered_target_fabric.id, null) : null
  )
  # The resource group ID is simply parent_id
  resource_group_id                  = var.parent_id
  role_definition_resource_substring = "/providers/Microsoft.Authorization/roleDefinitions"
  # ========================================
  # DRA (FABRIC AGENT) IDENTITIES
  # ========================================
  # Extract DRA (Fabric Agent) identity object IDs for role assignments
  source_dra_object_id = local.is_initialize_mode && length(data.azapi_resource_list.source_fabric_agents) > 0 ? try(
    [for agent in data.azapi_resource_list.source_fabric_agents[0].output.value :
      agent.properties.resourceAccessIdentity.objectId if(
        try(agent.properties.machineName, "") == var.source_appliance_name &&
        try(agent.properties.customProperties.instanceType, "") == local.source_fabric_instance_type &&
        try(agent.properties.isResponsive, false) == true
      )
    ][0],
    null
  ) : null
  # ========================================
  # FABRIC DISCOVERY
  # ========================================
  # Fabric instance types for matching
  source_fabric_instance_type = var.instance_type == "VMwareToAzStackHCI" ? "VMwareMigrate" : "HyperVMigrate"
  storage_account_name        = local.is_initialize_mode && var.source_appliance_name != null ? "migratersa${local.storage_account_suffix}" : ""
  # ========================================
  # STORAGE ACCOUNT
  # ========================================
  # Storage account name generation (similar to Python generate_hash_for_artifact)
  # Only calculate if we're in initialize mode to avoid null value errors
  storage_account_suffix = local.is_initialize_mode && var.source_appliance_name != null ? substr(md5("${var.source_appliance_name}${var.project_name}"), 0, 14) : ""
  subscription_id        = local.parsed_parent_id.subscription_id
  target_dra_object_id = local.is_initialize_mode && length(data.azapi_resource_list.target_fabric_agents) > 0 ? try(
    [for agent in data.azapi_resource_list.target_fabric_agents[0].output.value :
      agent.properties.resourceAccessIdentity.objectId if(
        try(agent.properties.machineName, "") == var.target_appliance_name &&
        try(agent.properties.customProperties.instanceType, "") == local.target_fabric_instance_type &&
        try(agent.properties.isResponsive, false) == true
      )
    ][0],
    null
  ) : null
  target_fabric_instance_type = "AzStackHCI"
  # ========================================
  # REPLICATION VAULT
  # ========================================
  # Check if vault exists in solution (handles both missing solution and missing vaultId)
  vault_exists_in_solution = local.is_initialize_mode && length(data.azapi_resource.replication_solution) > 0 && try(data.azapi_resource.replication_solution[0].output.properties.details.extendedDetails.vaultId, null) != null && try(data.azapi_resource.replication_solution[0].output.properties.details.extendedDetails.vaultId, "") != ""
}
