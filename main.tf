# Terraform Module for Azure Stack HCI Migration
# Resources only - see locals.tf for local values and data.tf for data sources

# ========================================
# MIGRATE PROJECT & SOLUTIONS
# ========================================

# Create new Azure Migrate Project (if requested)
resource "azapi_resource" "migrate_project" {
  count = local.create_new_project ? 1 : 0

  location  = local.effective_location
  name      = var.project_name
  parent_id = local.resource_group_id
  type      = "Microsoft.Migrate/migrateprojects@2020-06-01-preview"
  body = {
    properties = {
      publicNetworkAccess = var.connectivity_method == "Public-endpoint" ? "Enabled" : "Disabled"
    }
  }
  create_headers            = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  delete_headers            = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  read_headers              = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  schema_validation_enabled = false
  tags                      = var.tags
  update_headers            = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null

  identity {
    type = "SystemAssigned"
  }

  lifecycle {
    precondition {
      condition     = var.location != null
      error_message = "`var.location` is required when `create_migrate_project = true`. There is no existing project to discover the region from — supply the target Azure region explicitly."
    }
  }
}

# Solution 1: Servers-Assessment-ServerAssessment (Active)
resource "azapi_resource" "solution_assessment" {
  count = local.create_new_project ? 1 : 0

  name      = "Servers-Assessment-ServerAssessment"
  parent_id = azapi_resource.migrate_project[0].id
  type      = "Microsoft.Migrate/migrateprojects/solutions@2020-06-01-preview"
  body = {
    properties = {
      tool    = "ServerAssessment"
      purpose = "Assessment"
      goal    = "Servers"
      status  = "Active"
      details = null
    }
  }
  create_headers            = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  delete_headers            = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  read_headers              = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  schema_validation_enabled = false
  update_headers            = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
}

# Solution 2: Servers-Discovery-ServerDiscovery (Inactive)
resource "azapi_resource" "solution_discovery" {
  count = local.create_new_project ? 1 : 0

  name      = "Servers-Discovery-ServerDiscovery"
  parent_id = azapi_resource.migrate_project[0].id
  type      = "Microsoft.Migrate/migrateprojects/solutions@2020-06-01-preview"
  body = {
    properties = {
      tool    = "ServerDiscovery"
      purpose = "Discovery"
      goal    = "Servers"
      status  = "Inactive"
      details = null
    }
  }
  create_headers            = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  delete_headers            = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  read_headers              = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  schema_validation_enabled = false
  update_headers            = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null

  depends_on = [azapi_resource.solution_assessment]
}

# Solution 3: Servers-Migration-ServerMigration (Active)
resource "azapi_resource" "solution_migration" {
  count = local.create_new_project ? 1 : 0

  name      = "Servers-Migration-ServerMigration"
  parent_id = azapi_resource.migrate_project[0].id
  type      = "Microsoft.Migrate/migrateprojects/solutions@2020-06-01-preview"
  body = {
    properties = {
      tool    = "ServerMigration"
      purpose = "Migration"
      goal    = "Servers"
      status  = "Active"
      details = null
    }
  }
  create_headers            = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  delete_headers            = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  read_headers              = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  schema_validation_enabled = false
  update_headers            = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null

  depends_on = [azapi_resource.solution_discovery]
}

# Solution 4: Servers-Migration-ServerMigration_DataReplication (Inactive)
resource "azapi_resource" "solution_data_replication" {
  count = local.create_new_project ? 1 : 0

  name      = "Servers-Migration-ServerMigration_DataReplication"
  parent_id = azapi_resource.migrate_project[0].id
  type      = "Microsoft.Migrate/migrateprojects/solutions@2020-06-01-preview"
  body = {
    properties = {
      tool    = "ServerMigration_DataReplication"
      purpose = "Migration"
      goal    = "Servers"
      status  = "Inactive"
      details = null
    }
  }
  create_headers            = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  delete_headers            = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  read_headers              = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  schema_validation_enabled = false
  update_headers            = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null

  depends_on = [azapi_resource.solution_migration]
}

# Grant Azure Migrate Assessor role to project's managed identity on resource group
resource "azapi_resource" "migrate_project_role_assignment" {
  count = local.create_new_project ? 1 : 0

  name      = uuidv5("dns", "${azapi_resource.migrate_project[0].id}-assessor")
  parent_id = local.resource_group_id
  type      = "Microsoft.Authorization/roleAssignments@2022-04-01"
  body = {
    properties = {
      principalId      = azapi_resource.migrate_project[0].identity[0].principal_id
      roleDefinitionId = "/subscriptions/${local.subscription_id}/providers/Microsoft.Authorization/roleDefinitions/ba480ccd-6499-4709-b581-8f38bb215c63"
      principalType    = "ServicePrincipal"
    }
  }
  create_headers = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  delete_headers = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  read_headers   = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  update_headers = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null

  depends_on = [azapi_resource.solution_data_replication]
}

# ========================================
# INITIALIZE REPLICATION INFRASTRUCTURE
# ========================================

# Create replication vault if it doesn't exist
resource "azapi_resource" "replication_vault" {
  count = local.create_new_vault ? 1 : 0

  location  = local.effective_location
  name      = "${replace(var.project_name, "-", "")}replicationvault"
  parent_id = local.resource_group_id
  type      = "Microsoft.DataReplication/replicationVaults@2024-09-01"
  body = {
    properties = {}
  }
  create_headers = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  delete_headers = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  read_headers   = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  tags           = var.tags
  update_headers = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null

  identity {
    type = "SystemAssigned"
  }
}

# Create or update replication policy (skip if it already exists in brownfield)
resource "azapi_resource" "replication_policy" {
  count = local.is_initialize_mode && !local.replication_policy_exists ? 1 : 0

  name      = local.effective_policy_name
  parent_id = local.create_new_vault ? azapi_resource.replication_vault[0].id : data.azapi_resource.replication_vault[0].id
  type      = "Microsoft.DataReplication/replicationVaults/replicationPolicies@2024-09-01"
  body = {
    properties = {
      customProperties = {
        instanceType                      = local.effective_instance_type
        recoveryPointHistoryInMinutes     = var.replication_policy.recovery_point_history_minutes
        crashConsistentFrequencyInMinutes = var.replication_policy.crash_consistent_frequency_minutes
        appConsistentFrequencyInMinutes   = var.replication_policy.app_consistent_frequency_minutes
      }
    }
  }
  create_headers            = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  delete_headers            = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  read_headers              = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  schema_validation_enabled = false
  update_headers            = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null

  depends_on = [azapi_resource.replication_vault, data.azapi_resource.replication_vault]
}

# Create cache storage account if not provided.
# Honour an existing replicationStorageAccountId already recorded on the migrate
# project's replication solution so we do not create a duplicate (matches Az CLI/PS).
resource "azapi_resource" "cache_storage_account" {
  count = local.is_initialize_mode && var.cache_storage_account_id == null && !local.has_existing_replication_storage_account ? 1 : 0

  location  = local.effective_location
  name      = local.storage_account_name
  parent_id = local.resource_group_id
  type      = "Microsoft.Storage/storageAccounts@2023-01-01"
  body = {
    kind = "StorageV2"
    properties = {
      allowBlobPublicAccess       = false
      allowCrossTenantReplication = true
      minimumTlsVersion           = "TLS1_2"
      supportsHttpsTrafficOnly    = true
    }
    sku = {
      name = "Standard_LRS"
    }
  }
  create_headers         = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  delete_headers         = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  read_headers           = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  response_export_values = []
  tags                   = var.tags
  update_headers         = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null

  lifecycle {
    precondition {
      condition     = var.source_appliance_name != null
      error_message = "In 'initialize' mode, var.source_appliance_name must be set when a cache storage account needs to be created. Either provide var.source_appliance_name (used to deterministically name the storage account) or pass an existing var.cache_storage_account_id."
    }
  }
}

# Grant Contributor role to vault identity on storage account (skip if exists in brownfield)
resource "azapi_resource" "vault_storage_contributor" {
  count = local.is_initialize_mode && !local.vault_contributor_exists ? 1 : 0

  name      = uuidv5("dns", "${local.storage_account_name}-vault-contributor")
  parent_id = local.resolved_cache_storage_account_id
  type      = "Microsoft.Authorization/roleAssignments@2022-04-01"
  body = {
    properties = {
      principalId      = local.create_new_vault ? azapi_resource.replication_vault[0].identity[0].principal_id : data.azapi_resource.replication_vault[0].output.identity.principalId
      roleDefinitionId = "/subscriptions/${local.subscription_id}/providers/Microsoft.Authorization/roleDefinitions/b24988ac-6180-42a0-ab88-20f7382dd24c"
      principalType    = "ServicePrincipal"
    }
  }
  create_headers = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  delete_headers = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  read_headers   = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  update_headers = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
}

# Grant Storage Blob Data Contributor role to vault identity (skip if exists in brownfield)
resource "azapi_resource" "vault_storage_blob_contributor" {
  count = local.is_initialize_mode && !local.vault_blob_contributor_exists ? 1 : 0

  name      = uuidv5("dns", "${local.storage_account_name}-vault-blob-contributor")
  parent_id = local.resolved_cache_storage_account_id
  type      = "Microsoft.Authorization/roleAssignments@2022-04-01"
  body = {
    properties = {
      principalId      = local.create_new_vault ? azapi_resource.replication_vault[0].identity[0].principal_id : data.azapi_resource.replication_vault[0].output.identity.principalId
      roleDefinitionId = "/subscriptions/${local.subscription_id}/providers/Microsoft.Authorization/roleDefinitions/ba92f5b4-2d11-453d-a403-e96b0029c9fe"
      principalType    = "ServicePrincipal"
    }
  }
  create_headers = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  delete_headers = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  read_headers   = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  update_headers = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
}

# ========================================
# DRA (Fabric Agent) Role Assignments
# Note: These use has_fabric_inputs for count (known at plan time) and rely on
#       depends_on to ensure DRA data is available before the role assignment.
#       If DRA lookup fails, the principal_id will be null and Terraform will error,
#       which is the expected behavior.
# ========================================

# Grant Contributor role to source DRA identity (skip if exists in brownfield)
resource "azapi_resource" "source_dra_storage_contributor" {
  count = local.is_initialize_mode && local.has_fabric_inputs && !local.source_dra_contributor_exists ? 1 : 0

  name      = uuidv5("dns", "${local.storage_account_name}-source-dra-contributor")
  parent_id = local.resolved_cache_storage_account_id
  type      = "Microsoft.Authorization/roleAssignments@2022-04-01"
  body = {
    properties = {
      principalId      = local.source_dra_object_id
      roleDefinitionId = "/subscriptions/${local.subscription_id}/providers/Microsoft.Authorization/roleDefinitions/b24988ac-6180-42a0-ab88-20f7382dd24c"
      principalType    = "ServicePrincipal"
    }
  }
  create_headers = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  delete_headers = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  read_headers   = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  update_headers = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null

  depends_on = [data.azapi_resource_list.source_fabric_agents]
}

# Grant Storage Blob Data Contributor role to source DRA identity (skip if exists in brownfield)
resource "azapi_resource" "source_dra_storage_blob_contributor" {
  count = local.is_initialize_mode && local.has_fabric_inputs && !local.source_dra_blob_exists ? 1 : 0

  name      = uuidv5("dns", "${local.storage_account_name}-source-dra-blob")
  parent_id = local.resolved_cache_storage_account_id
  type      = "Microsoft.Authorization/roleAssignments@2022-04-01"
  body = {
    properties = {
      principalId      = local.source_dra_object_id
      roleDefinitionId = "/subscriptions/${local.subscription_id}/providers/Microsoft.Authorization/roleDefinitions/ba92f5b4-2d11-453d-a403-e96b0029c9fe"
      principalType    = "ServicePrincipal"
    }
  }
  create_headers = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  delete_headers = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  read_headers   = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  update_headers = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null

  depends_on = [data.azapi_resource_list.source_fabric_agents]
}

# Grant Contributor role to target DRA identity (skip if exists in brownfield)
resource "azapi_resource" "target_dra_storage_contributor" {
  count = local.is_initialize_mode && local.has_fabric_inputs && !local.target_dra_contributor_exists ? 1 : 0

  name      = uuidv5("dns", "${local.storage_account_name}-target-dra-contributor")
  parent_id = local.resolved_cache_storage_account_id
  type      = "Microsoft.Authorization/roleAssignments@2022-04-01"
  body = {
    properties = {
      principalId      = local.target_dra_object_id
      roleDefinitionId = "/subscriptions/${local.subscription_id}/providers/Microsoft.Authorization/roleDefinitions/b24988ac-6180-42a0-ab88-20f7382dd24c"
      principalType    = "ServicePrincipal"
    }
  }
  create_headers = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  delete_headers = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  read_headers   = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  update_headers = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null

  depends_on = [data.azapi_resource_list.target_fabric_agents]
}

# Grant Storage Blob Data Contributor role to target DRA identity (skip if exists in brownfield)
resource "azapi_resource" "target_dra_storage_blob_contributor" {
  count = local.is_initialize_mode && local.has_fabric_inputs && !local.target_dra_blob_exists ? 1 : 0

  name      = uuidv5("dns", "${local.storage_account_name}-target-dra-blob")
  parent_id = local.resolved_cache_storage_account_id
  type      = "Microsoft.Authorization/roleAssignments@2022-04-01"
  body = {
    properties = {
      principalId      = local.target_dra_object_id
      roleDefinitionId = "/subscriptions/${local.subscription_id}/providers/Microsoft.Authorization/roleDefinitions/ba92f5b4-2d11-453d-a403-e96b0029c9fe"
      principalType    = "ServicePrincipal"
    }
  }
  create_headers = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  delete_headers = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  read_headers   = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  update_headers = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null

  depends_on = [data.azapi_resource_list.target_fabric_agents]
}

# Update AMH solution with storage account ID and vault ID
# Uses retry instead of time_sleep to handle eventual consistency for RBAC propagation
resource "azapi_update_resource" "update_solution_storage" {
  count = local.is_initialize_mode ? 1 : 0

  resource_id = data.azapi_resource.replication_solution[0].id
  type        = "Microsoft.Migrate/migrateprojects/solutions@2020-05-01"
  body = {
    properties = {
      details = {
        extendedDetails = merge(
          try(data.azapi_resource.replication_solution[0].output.properties.details.extendedDetails, {}),
          {
            replicationStorageAccountId = local.resolved_cache_storage_account_id
            vaultId                     = local.create_new_vault ? azapi_resource.replication_vault[0].id : data.azapi_resource.replication_vault[0].id
          }
        )
      }
    }
  }
  read_headers = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  # Retry on authorization/propagation errors instead of using time_sleep
  retry = {
    error_message_regex  = ["AuthorizationFailed", "PrincipalNotFound", "does not have authorization", "RoleAssignmentNotFound", "InternalServerError", "RetryableError"]
    interval_seconds     = 15
    max_interval_seconds = 60
  }
  update_headers = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null

  timeouts {
    update = "10m"
  }

  depends_on = [
    azapi_resource.replication_vault,
    azapi_resource.vault_storage_contributor,
    azapi_resource.vault_storage_blob_contributor,
    azapi_resource.source_dra_storage_contributor,
    azapi_resource.source_dra_storage_blob_contributor,
    azapi_resource.target_dra_storage_contributor,
    azapi_resource.target_dra_storage_blob_contributor
  ]
}

# Create replication extension (skip if it already exists in brownfield)
resource "azapi_resource" "replication_extension" {
  count = local.is_initialize_mode && local.has_fabric_inputs && !local.replication_extension_exists ? 1 : 0

  name      = "${basename(local.resolved_source_fabric_id)}-${basename(local.resolved_target_fabric_id)}-MigReplicationExtn"
  parent_id = local.create_new_vault ? azapi_resource.replication_vault[0].id : data.azapi_resource.replication_vault[0].id
  type      = "Microsoft.DataReplication/replicationVaults/replicationExtensions@2024-09-01"
  body = {
    properties = {
      customProperties = local.effective_instance_type == "VMwareToAzStackHCI" ? {
        azStackHciFabricArmId       = local.resolved_target_fabric_id
        storageAccountId            = local.resolved_cache_storage_account_id
        storageAccountSasSecretName = null
        instanceType                = local.effective_instance_type
        vmwareFabricArmId           = local.resolved_source_fabric_id
        } : {
        azStackHciFabricArmId       = local.resolved_target_fabric_id
        storageAccountId            = local.resolved_cache_storage_account_id
        storageAccountSasSecretName = null
        instanceType                = local.effective_instance_type
        hyperVFabricArmId           = local.resolved_source_fabric_id
      }
    }
  }
  create_headers = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  delete_headers = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  read_headers   = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  # Retry on propagation/consistency errors - handles eventual consistency without time_sleep
  retry = {
    error_message_regex  = ["RetryableError", "InternalServerError", "RequestTimeout", "AuthorizationFailed", "PrincipalNotFound", "ResourceNotFound", "SolutionNotReady"]
    interval_seconds     = 15
    max_interval_seconds = 60
  }
  schema_validation_enabled = false
  update_headers            = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null

  timeouts {
    create = "15m"
    delete = "5m"
    read   = "2m"
  }

  depends_on = [
    azapi_update_resource.update_solution_storage,
    azapi_resource.replication_policy
  ]
}

# ========================================
# CREATE SERVER REPLICATION
# ========================================

# Create protected item (VM replication)
# IMPORTANT: The protected item name must be the source machine name (last segment of machine_id),
# NOT the target VM name. The targetVmName goes inside customProperties.
resource "azapi_resource" "protected_item" {
  count = local.is_replicate_mode && (var.machine_id != null || var.machine_name != null) ? 1 : 0

  # Protected item name must be the source machine name from machine_id (e.g., "100-69-177-104-36bf83bc-c03b-4c08-853c-187db9aa17e8_50232086-5a0d-7205-68e2-bc2391e7a0a7")
  # This matches the CLI behavior in create_protected_item() which uses machine_name
  name      = var.machine_name != null ? var.machine_name : basename(var.machine_id)
  parent_id = local.resolved_vault_id
  type      = "Microsoft.DataReplication/replicationVaults/protectedItems@2024-09-01"
  body = {
    properties = {
      policyName               = local.effective_policy_name
      replicationExtensionName = local.effective_replication_extension_name
      customProperties = {
        instanceType                     = local.effective_instance_type
        targetArcClusterCustomLocationId = coalesce(var.custom_location_id, "")
        customLocationRegion             = local.effective_location
        fabricDiscoveryMachineId         = var.machine_id != null ? var.machine_id : "${local.migrate_project_id}/machines/${var.machine_name}"
        # Power user mode: explicit disks_to_include.
        # Simple mode: single OS disk entry built from os_disk_id; size is
        # left at 0 so the API derives it from the discovered disk
        # (mirrors `New-AzMigrateLocalServerReplication -OSDiskID`).
        disksToInclude = length(var.disks_to_include) > 0 ? [
          for disk in var.disks_to_include : {
            diskId                 = disk.disk_id
            diskSizeGB             = disk.disk_size_gb
            diskFileFormat         = disk.disk_file_format
            isOsDisk               = disk.is_os_disk
            isDynamic              = disk.is_dynamic
            diskPhysicalSectorSize = 512
          }
          ] : var.os_disk_id != null ? [{
            diskId                 = var.os_disk_id
            diskSizeGB             = 0
            diskFileFormat         = "VHDX"
            isOsDisk               = true
            isDynamic              = true
            diskPhysicalSectorSize = 512
        }] : []
        targetVmName            = var.target_vm_name
        targetResourceGroupId   = var.target_resource_group_id
        storageContainerId      = var.target_storage_path_id
        hyperVGeneration        = var.target_vm_compute.hyperv_generation
        targetCpuCores          = var.target_vm_compute.cpu_cores
        sourceCpuCores          = var.target_vm_compute.cpu_cores
        isDynamicRam            = var.target_vm_compute.is_dynamic_memory_enabled
        sourceMemoryInMegaBytes = var.target_vm_compute.ram_mb
        targetMemoryInMegaBytes = floor(var.target_vm_compute.ram_mb)
        # Power user mode: explicit nics_to_include.
        # Simple mode: single NIC entry built from target_virtual_switch_id;
        # nicId is left null so the API matches it against the discovered NIC
        # set (mirrors `-TargetVirtualSwitch`).
        nicsToInclude = length(var.nics_to_include) > 0 ? [
          for nic in var.nics_to_include : {
            nicId                    = nic.nic_id
            selectionTypeForFailover = nic.selection_type
            targetNetworkId          = nic.target_network_id
            testNetworkId            = nic.test_network_id != null ? nic.test_network_id : nic.target_network_id
          }
          ] : var.target_virtual_switch_id != null ? [{
            nicId                    = null
            selectionTypeForFailover = "SelectedByUser"
            targetNetworkId          = var.target_virtual_switch_id
            testNetworkId            = var.target_test_virtual_switch_id != null ? var.target_test_virtual_switch_id : var.target_virtual_switch_id
        }] : []
        dynamicMemoryConfig = {
          maximumMemoryInMegaBytes     = 1048576
          minimumMemoryInMegaBytes     = 512
          targetMemoryBufferPercentage = 20
        }
        sourceFabricAgentName = local.effective_source_fabric_agent_name
        targetFabricAgentName = local.effective_target_fabric_agent_name
        runAsAccountId        = var.run_as_account_id
        targetHCIClusterId    = var.target_hci_cluster_id
      }
    }
  }
  create_headers            = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  delete_headers            = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  ignore_missing_property   = true
  locks                     = []
  read_headers              = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  response_export_values    = ["properties.replicationHealth"]
  schema_validation_enabled = false
  update_headers            = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null

  timeouts {
    create = "30m"
    read   = "10m"
    update = "30m"
  }

  lifecycle {
    ignore_changes = [
      body
    ]
  }
}

# ========================================
# MIGRATE OPERATION (PLANNED FAILOVER)
# ========================================

# Execute planned failover (migration) operation - HyperV
resource "azapi_resource_action" "planned_failover_hyperv" {
  count = local.is_migrate_mode && local.effective_instance_type == "HyperVToAzStackHCI" ? 1 : 0

  action      = "plannedFailover"
  method      = "POST"
  resource_id = var.protected_item_id
  type        = "Microsoft.DataReplication/replicationVaults/protectedItems@2024-09-01"
  body = {
    properties = {
      customProperties = {
        instanceType     = "HyperVToAzStackHCI"
        shutdownSourceVM = var.shutdown_source_vm
      }
    }
  }

  timeouts {
    create = "180m"
    update = "180m"
  }

  # Ensure validation happens first
  depends_on = [
    data.azapi_resource.protected_item_to_migrate
  ]
}

# Execute planned failover (migration) operation - VMware
resource "azapi_resource_action" "planned_failover_vmware" {
  count = local.is_migrate_mode && local.effective_instance_type == "VMwareToAzStackHCI" ? 1 : 0

  action      = "plannedFailover"
  method      = "POST"
  resource_id = var.protected_item_id
  type        = "Microsoft.DataReplication/replicationVaults/protectedItems@2024-09-01"
  body = {
    properties = {
      customProperties = {
        instanceType     = "VMwareToAzStackHCI"
        shutdownSourceVM = var.shutdown_source_vm
      }
    }
  }

  timeouts {
    create = "180m"
    update = "180m"
  }

  # Ensure validation happens first
  depends_on = [
    data.azapi_resource.protected_item_to_migrate
  ]
}

# ========================================
# REMOVE PROTECTED ITEMS OPERATION
# ========================================

# Remove protected item (VM replication)
resource "azapi_resource_action" "remove_replication" {
  count = local.is_remove_mode ? 1 : 0

  action = ""
  method = "DELETE"
  # Add forceDelete query parameter as a map of lists
  query_parameters = {
    forceDelete = [tostring(var.force_remove)]
  }
  resource_id = var.target_object_id
  type        = "Microsoft.DataReplication/replicationVaults/protectedItems@2024-09-01"

  # Ensure validation happens first
  depends_on = [
    data.azapi_resource.protected_item_to_remove
  ]
}

# ========================================
# AVM REQUIRED INTERFACES
# ========================================

# Management lock targets the module's primary resource (the migrate project).
# Locking the entire resource group would also lock unrelated resources, which is
# unsafe for an AVM module that is one of many things in the RG.
resource "azapi_resource" "management_lock" {
  count = var.lock != null && local.migrate_project_id != null ? 1 : 0

  name      = coalesce(var.lock.name, "lock-${var.lock.kind}")
  parent_id = local.migrate_project_id
  type      = "Microsoft.Authorization/locks@2020-05-01"
  body = {
    properties = {
      level = var.lock.kind
      notes = var.lock.kind == "CanNotDelete" ? "Cannot delete the resource or its child resources." : "Cannot delete or modify the resource or its child resources."
    }
  }
  create_headers = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  delete_headers = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  read_headers   = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  update_headers = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null

  lifecycle {
    precondition {
      condition     = local.migrate_project_id != null
      error_message = "var.lock is set but the module has no primary resource to lock. Provide var.project_name (and var.create_migrate_project if needed) so the lock can be applied to the migrate project."
    }
  }
}

# Diagnostic settings target the replication vault (the only resource in this
# module that emits diagnostic logs and metrics). The for_each uses
# var.diagnostic_settings directly so the keys are known at plan time; the
# precondition ensures a vault is available whenever any settings are requested.
resource "azapi_resource" "diagnostic_setting" {
  for_each = var.diagnostic_settings

  name      = coalesce(each.value.name, "diag-${each.key}")
  parent_id = local.resolved_vault_id
  type      = "Microsoft.Insights/diagnosticSettings@2021-05-01-preview"
  body = {
    properties = {
      workspaceId                 = each.value.workspace_resource_id
      storageAccountId            = each.value.storage_account_resource_id
      eventHubAuthorizationRuleId = each.value.event_hub_authorization_rule_resource_id
      eventHubName                = each.value.event_hub_name
      marketplacePartnerId        = each.value.marketplace_partner_resource_id
      logAnalyticsDestinationType = each.value.workspace_resource_id != null ? each.value.log_analytics_destination_type : null
      logs = concat(
        [for category in each.value.log_categories : {
          category      = category
          categoryGroup = null
          enabled       = true
        }],
        [for group in each.value.log_groups : {
          category      = null
          categoryGroup = group
          enabled       = true
        }]
      )
      metrics = [for category in each.value.metric_categories : {
        category = category
        enabled  = true
      }]
    }
  }
  create_headers            = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  delete_headers            = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  read_headers              = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  schema_validation_enabled = false
  update_headers            = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null

  lifecycle {
    precondition {
      condition     = local.resolved_vault_id != null
      error_message = "var.diagnostic_settings is set but no replication vault is available to attach them to. Either run the module in 'initialize' mode (which resolves or creates a vault) or pass var.replication_vault_id."
    }
  }
}

resource "azapi_resource" "role_assignment" {
  for_each = var.role_assignments

  name      = uuidv5("dns", "${each.key}-${each.value.principal_id}-${each.value.role_definition_id_or_name}")
  parent_id = local.resource_group_id
  type      = "Microsoft.Authorization/roleAssignments@2022-04-01"
  body = {
    properties = {
      principalId                        = each.value.principal_id
      roleDefinitionId                   = strcontains(lower(each.value.role_definition_id_or_name), lower(local.role_definition_resource_substring)) ? each.value.role_definition_id_or_name : "/subscriptions/${local.subscription_id}/providers/Microsoft.Authorization/roleDefinitions/${each.value.role_definition_id_or_name}"
      principalType                      = each.value.principal_type
      condition                          = each.value.condition
      conditionVersion                   = each.value.condition_version
      delegatedManagedIdentityResourceId = each.value.delegated_managed_identity_resource_id
    }
  }
  create_headers = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  delete_headers = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  read_headers   = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  update_headers = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
}
