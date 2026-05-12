# Local values for Azure Stack HCI Migration module

locals {
  # Storage Blob Data Contributor role GUID
  _blob_contributor_role_guid = "ba92f5b4-2d11-453d-a403-e96b0029c9fe"
  # Contributor role GUID
  _contributor_role_guid = "b24988ac-6180-42a0-ab88-20f7382dd24c"
  # ========================================
  # BROWNFIELD DETECTION
  # ========================================
  # Detect existing role assignments on the cache storage account.
  # When cache_storage_account_id is provided (brownfield), query Azure for existing assignments
  # and skip creation if an assignment for the same principal+role already exists.
  # In greenfield (cache_storage_account_id is null), these are always false → create everything.
  _existing_role_assignment_keys = var.cache_storage_account_id != null && length(data.azapi_resource_list.cache_storage_role_assignments) > 0 ? toset([
    for ra in try(data.azapi_resource_list.cache_storage_role_assignments[0].output.value, []) :
    "${lower(try(ra.properties.principalId, ""))}-${lower(basename(try(ra.properties.roleDefinitionId, "")))}"
  ]) : toset([])
  # Vault principal ID from existing vault data source (brownfield)
  _vault_principal_id = local.vault_exists_in_solution ? try(data.azapi_resource.replication_vault[0].output.identity.principalId, null) : null
  # ========================================
  # PROJECT
  # ========================================
  # Create new Migrate project if project_name is provided and create_migrate_project is true
  create_new_project = var.create_migrate_project && var.project_name != null
  # Only create new vault if in initialize mode and vault doesn't exist
  create_new_vault = local.is_initialize_mode && !local.vault_exists_in_solution
  # Auto-discover source fabric from appliance name (initialize or replicate mode).
  # Finds fabric where: name starts with/contains appliance_name AND instanceType matches AND provisioningState is Succeeded.
  # Matches the PowerShell `Initialize-AzMigrateLocalReplicationInfrastructure` behaviour — the caller never supplies a fabric ID.
  discovered_source_fabric = local.needs_fabric_discovery && var.source_appliance_name != null && length(data.azapi_resource_list.replication_fabrics) > 0 ? try(
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
  discovered_target_fabric = local.needs_fabric_discovery && var.target_appliance_name != null && length(data.azapi_resource_list.replication_fabrics) > 0 ? try(
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
  # Determine if we have fabric configuration inputs (used for count — must be known at plan time).
  # Fabrics are resolved internally from appliance names (parity with Az.Migrate PowerShell),
  # so the predicate only needs the two appliance-name variables.
  has_fabric_inputs = var.source_appliance_name != null && var.target_appliance_name != null
  # Modes that need to discover fabrics/agents from the project (initialize creates them, replicate consumes them).
  needs_fabric_discovery = local.is_initialize_mode || local.is_replicate_mode
  # 1:1 mapping from source_machine_type to the protected-item instanceType the API expects.
  effective_instance_type = var.source_machine_type == "HyperV" ? "HyperVToAzStackHCI" : "VMwareToAzStackHCI"
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
  # Resolve fabric IDs purely from the auto-discovered fabrics. The PowerShell cmdlet
  # does not expose fabric IDs to the user, so neither do we.
  resolved_source_fabric_id = try(local.discovered_source_fabric.id, null)
  resolved_target_fabric_id = try(local.discovered_target_fabric.id, null)
  # The resource group ID is simply parent_id
  resource_group_id                  = var.parent_id
  role_definition_resource_substring = "/providers/Microsoft.Authorization/roleDefinitions"
  source_dra_blob_exists             = length(local._existing_role_assignment_keys) == 0 ? false : (local.source_dra_object_id != null && contains(local._existing_role_assignment_keys, "${lower(coalesce(local.source_dra_object_id, "00000000-0000-0000-0000-000000000000"))}-${local._blob_contributor_role_guid}"))
  source_dra_contributor_exists      = length(local._existing_role_assignment_keys) == 0 ? false : (local.source_dra_object_id != null && contains(local._existing_role_assignment_keys, "${lower(coalesce(local.source_dra_object_id, "00000000-0000-0000-0000-000000000000"))}-${local._contributor_role_guid}"))
  # ========================================
  # DRA (FABRIC AGENT) IDENTITIES
  # ========================================
  # Extract DRA (Fabric Agent) identity object IDs for role assignments
  source_dra_object_id = local.needs_fabric_discovery && length(data.azapi_resource_list.source_fabric_agents) > 0 ? try(
    [for agent in data.azapi_resource_list.source_fabric_agents[0].output.value :
      agent.properties.resourceAccessIdentity.objectId if(
        try(agent.properties.machineName, "") == var.source_appliance_name &&
        try(agent.properties.customProperties.instanceType, "") == local.source_fabric_instance_type &&
        try(agent.properties.isResponsive, false) == true
      )
    ][0],
    null
  ) : null
  # Auto-resolve the DRA names that Az.Migrate normally looks up itself. Picks the
  # first responsive agent whose machineName matches the appliance and whose
  # instanceType matches the migration direction.
  effective_source_fabric_agent_name = local.needs_fabric_discovery && length(data.azapi_resource_list.source_fabric_agents) > 0 ? try(
    [for agent in data.azapi_resource_list.source_fabric_agents[0].output.value :
      try(agent.name, null) if(
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
  source_fabric_instance_type = local.effective_instance_type == "VMwareToAzStackHCI" ? "VMwareMigrate" : "HyperVMigrate"
  storage_account_name        = local.is_initialize_mode && var.source_appliance_name != null ? "migratersa${local.storage_account_suffix}" : ""
  # ========================================
  # STORAGE ACCOUNT
  # ========================================
  # Storage account name generation (similar to Python generate_hash_for_artifact)
  # Only calculate if we're in initialize mode to avoid null value errors
  storage_account_suffix = local.is_initialize_mode && var.source_appliance_name != null ? substr(md5("${var.source_appliance_name}${var.project_name}"), 0, 14) : ""
  # Detect storage account already associated with the migrate project's replication solution.
  # When the solution's extendedDetails already contains a replicationStorageAccountId we
  # reuse that account instead of provisioning a duplicate (parity with Az CLI / Az PowerShell).
  existing_replication_storage_account_id  = local.is_initialize_mode && length(data.azapi_resource.replication_solution) > 0 ? try(data.azapi_resource.replication_solution[0].output.properties.details.extendedDetails.replicationStorageAccountId, null) : null
  has_existing_replication_storage_account = local.existing_replication_storage_account_id != null && local.existing_replication_storage_account_id != ""
  # Resolved cache storage account ID with precedence:
  #   1. Caller-supplied var.cache_storage_account_id (explicit override)
  #   2. Existing replicationStorageAccountId already recorded on the solution
  #   3. Newly created cache storage account managed by this module
  resolved_cache_storage_account_id = var.cache_storage_account_id != null ? var.cache_storage_account_id : (
    local.has_existing_replication_storage_account ? local.existing_replication_storage_account_id : (
      length(azapi_resource.cache_storage_account) > 0 ? azapi_resource.cache_storage_account[0].id : null
    )
  )
  subscription_id = local.parsed_parent_id.subscription_id
  target_dra_object_id = local.needs_fabric_discovery && length(data.azapi_resource_list.target_fabric_agents) > 0 ? try(
    [for agent in data.azapi_resource_list.target_fabric_agents[0].output.value :
      agent.properties.resourceAccessIdentity.objectId if(
        try(agent.properties.machineName, "") == var.target_appliance_name &&
        try(agent.properties.customProperties.instanceType, "") == local.target_fabric_instance_type &&
        try(agent.properties.isResponsive, false) == true
      )
    ][0],
    null
  ) : null
  effective_target_fabric_agent_name = local.needs_fabric_discovery && length(data.azapi_resource_list.target_fabric_agents) > 0 ? try(
    [for agent in data.azapi_resource_list.target_fabric_agents[0].output.value :
      try(agent.name, null) if(
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
  # Check if vault exists in solution (handles both missing solution and missing vaultId).
  # Extended to replicate/list/get/jobs modes too — these read the solution and want the vault.
  vault_exists_in_solution = (local.is_initialize_mode || local.is_replicate_mode || local.is_list_mode || local.is_get_mode || local.is_jobs_mode) && length(data.azapi_resource.replication_solution) > 0 && try(data.azapi_resource.replication_solution[0].output.properties.details.extendedDetails.vaultId, null) != null && try(data.azapi_resource.replication_solution[0].output.properties.details.extendedDetails.vaultId, "") != ""
  # Resolved vault ID for downstream consumers. Order:
  #   1. Created vault (initialize mode)
  #   2. Vault discovered on the project's Server Migration solution
  #   3. Explicit var.replication_vault_id (legacy/override)
  resolved_vault_id = (
    local.create_new_vault ? azapi_resource.replication_vault[0].id :
    local.vault_exists_in_solution ? data.azapi_resource.replication_vault[0].id :
    var.replication_vault_id
  )
  # Auto-resolve the policy name to the deterministic Az.Migrate naming pattern
  # `<vault-name><instance-type>policy` when the caller did not supply one.
  effective_policy_name = coalesce(
    var.replication_policy.name,
    local.resolved_vault_id != null ? "${basename(local.resolved_vault_id)}${local.effective_instance_type}policy" : null,
    "unknown-policy"
  )
  # Auto-resolve the replication extension name to the deterministic Az.Migrate
  # naming pattern `<source-fabric>-<target-fabric>-MigReplicationExtn` when both
  # fabrics can be resolved.
  effective_replication_extension_name = (
    local.resolved_source_fabric_id != null && local.resolved_target_fabric_id != null ?
    "${basename(local.resolved_source_fabric_id)}-${basename(local.resolved_target_fabric_id)}-MigReplicationExtn" :
    null
  )
  # ========================================
  # BROWNFIELD IDEMPOTENCY GUARDS
  # ========================================
  # `*_exists` predicates consumed by `count` on resources that must skip
  # creation when the target object is already on the vault / storage account.
  # All default to `false` in greenfield, so the resource is created.
  #
  # Short-circuit on `vault_exists_in_solution`: if the vault is being created
  # this plan, no child policies/extensions can pre-exist, and short-circuiting
  # keeps these locals plan-time-known (the alternative path threads
  # apply-time-unknown values from `azapi_resource.replication_vault[0]`).
  replication_policy_exists = local.vault_exists_in_solution && local.effective_policy_name != null && contains(
    [for p in try(data.azapi_resource_list.existing_policies[0].output.value, []) : try(p.name, "")],
    local.effective_policy_name
  )
  replication_extension_exists = local.vault_exists_in_solution && local.effective_replication_extension_name != null && contains(
    [for e in try(data.azapi_resource_list.existing_extensions[0].output.value, []) : try(e.name, "")],
    local.effective_replication_extension_name
  )
  # ARM IDs / names of existing brownfield objects, used by outputs that need to
  # return the actual resource even when the module skipped creation.
  existing_policy_id = local.replication_policy_exists ? try(
    [for p in data.azapi_resource_list.existing_policies[0].output.value : try(p.id, null) if try(p.name, "") == local.effective_policy_name][0],
    null
  ) : null
  existing_extension_id = local.replication_extension_exists ? try(
    [for e in data.azapi_resource_list.existing_extensions[0].output.value : try(e.id, null) if try(e.name, "") == local.effective_replication_extension_name][0],
    null
  ) : null
  existing_extension_name = local.replication_extension_exists ? local.effective_replication_extension_name : null
  # Vault identity role assignments on the cache storage account
  vault_contributor_exists = length(local._existing_role_assignment_keys) == 0 ? false : (
    local._vault_principal_id != null && contains(
      local._existing_role_assignment_keys,
      "${lower(coalesce(local._vault_principal_id, "00000000-0000-0000-0000-000000000000"))}-${local._contributor_role_guid}"
    )
  )
  vault_blob_contributor_exists = length(local._existing_role_assignment_keys) == 0 ? false : (
    local._vault_principal_id != null && contains(
      local._existing_role_assignment_keys,
      "${lower(coalesce(local._vault_principal_id, "00000000-0000-0000-0000-000000000000"))}-${local._blob_contributor_role_guid}"
    )
  )
  # Target DRA role assignments on the cache storage account
  target_dra_contributor_exists = length(local._existing_role_assignment_keys) == 0 ? false : (
    local.target_dra_object_id != null && contains(
      local._existing_role_assignment_keys,
      "${lower(coalesce(local.target_dra_object_id, "00000000-0000-0000-0000-000000000000"))}-${local._contributor_role_guid}"
    )
  )
  target_dra_blob_exists = length(local._existing_role_assignment_keys) == 0 ? false : (
    local.target_dra_object_id != null && contains(
      local._existing_role_assignment_keys,
      "${lower(coalesce(local.target_dra_object_id, "00000000-0000-0000-0000-000000000000"))}-${local._blob_contributor_role_guid}"
    )
  )
}
