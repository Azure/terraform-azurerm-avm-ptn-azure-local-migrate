# --------------------------------------------------------------------------------------------
# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License. See License.txt in the project root for license information.
# --------------------------------------------------------------------------------------------
#
# Terraform Module for Azure Stack HCI Migration

# ========================================
# LOCAL VALUES
# ========================================

locals {
  # Determine operation mode
  is_discover_mode   = var.operation_mode == "discover"
  is_get_mode        = var.operation_mode == "get"
  is_initialize_mode = var.operation_mode == "initialize"
  is_jobs_mode       = var.operation_mode == "jobs"
  is_list_mode       = var.operation_mode == "list"
  is_migrate_mode    = var.operation_mode == "migrate"
  is_remove_mode     = var.operation_mode == "remove"
  is_replicate_mode  = var.operation_mode == "replicate"
  # Resource group reference
  resource_group_name  = var.resource_group_name
  storage_account_name = local.is_initialize_mode && var.source_appliance_name != null ? "migratersa${local.storage_account_suffix}" : ""
  # Storage account name generation (similar to Python generate_hash_for_artifact)
  # Only calculate if we're in initialize mode to avoid null value errors
  storage_account_suffix = local.is_initialize_mode && var.source_appliance_name != null ? substr(md5("${var.source_appliance_name}${var.project_name}"), 0, 14) : ""
  # Check if vault exists in solution (handles both missing solution and missing vaultId)
  vault_exists_in_solution = local.is_initialize_mode && length(data.azapi_resource.replication_solution) > 0 && try(data.azapi_resource.replication_solution[0].output.properties.details.extendedDetails.vaultId, null) != null && try(data.azapi_resource.replication_solution[0].output.properties.details.extendedDetails.vaultId, "") != ""
  # Only create new vault if in initialize mode and vault doesn't exist
  create_new_vault = local.is_initialize_mode && !local.vault_exists_in_solution

  # Fabric instance types for matching
  source_fabric_instance_type = var.instance_type == "VMwareToAzStackHCI" ? "VMwareMigrate" : "HyperVMigrate"
  target_fabric_instance_type = "AzStackHCI"

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

  # Auto-discover target fabric from appliance name (matches CLI behavior)
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

  # Resolve fabric IDs: priority order is explicit ID > auto-discovered from appliance name
  resolved_source_fabric_id = var.source_fabric_id != null ? var.source_fabric_id : (
    local.discovered_source_fabric != null ? try(local.discovered_source_fabric.id, null) : null
  )
  resolved_target_fabric_id = var.target_fabric_id != null ? var.target_fabric_id : (
    local.discovered_target_fabric != null ? try(local.discovered_target_fabric.id, null) : null
  )

  # Determine if we have fabric configuration inputs (used for count - must be known at plan time)
  # These check if the user provided either explicit IDs or appliance names for discovery
  has_fabric_inputs = (var.source_fabric_id != null || var.source_appliance_name != null) && (var.target_fabric_id != null || var.target_appliance_name != null)

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
}

# ========================================
# DATA SOURCES
# ========================================

# Get current subscription
data "azurerm_client_config" "current" {}

# Get resource group
data "azurerm_resource_group" "this" {
  name = var.resource_group_name
}

# Get Azure Migrate Project (for all modes)
data "azapi_resource" "migrate_project" {
  count = var.project_name != null ? 1 : 0

  name      = var.project_name
  parent_id = data.azurerm_resource_group.this.id
  type      = "Microsoft.Migrate/migrateprojects@2020-05-01"
}

# Get Discovery Solution (needed for appliance mapping)
data "azapi_resource" "discovery_solution" {
  count = local.is_initialize_mode || local.is_replicate_mode ? 1 : 0

  name      = "Servers-Discovery-ServerDiscovery"
  parent_id = data.azapi_resource.migrate_project[0].id
  type      = "Microsoft.Migrate/migrateprojects/solutions@2020-05-01"
}

# Get Data Replication Solution
data "azapi_resource" "replication_solution" {
  count = (local.is_initialize_mode || local.is_replicate_mode || local.is_list_mode || local.is_get_mode || local.is_jobs_mode) && var.project_name != null ? 1 : 0

  name                   = "Servers-Migration-ServerMigration_DataReplication"
  parent_id              = data.azapi_resource.migrate_project[0].id
  type                   = "Microsoft.Migrate/migrateprojects/solutions@2020-05-01"
  response_export_values = ["*"]
}

# ========================================
# DISCOVER SERVERS
# ========================================

# Query discovered servers from VMware or HyperV sites
data "azapi_resource_list" "discovered_servers" {
  count = local.is_discover_mode ? 1 : 0

  parent_id = var.appliance_name != null ? "${data.azurerm_resource_group.this.id}/providers/Microsoft.OffAzure/${var.source_machine_type == "HyperV" ? "HyperVSites" : "VMwareSites"}/${var.appliance_name}" : data.azapi_resource.migrate_project[0].id
  type      = var.appliance_name != null ? (var.source_machine_type == "HyperV" ? "Microsoft.OffAzure/HyperVSites/machines@2023-06-06" : "Microsoft.OffAzure/VMwareSites/machines@2023-06-06") : "Microsoft.Migrate/migrateprojects/machines@2020-05-01"
}

# ========================================
#  INITIALIZE REPLICATION INFRASTRUCTURE
# ========================================

# Create replication vault if it doesn't exist
resource "azapi_resource" "replication_vault" {
  count = local.create_new_vault ? 1 : 0

  location  = data.azurerm_resource_group.this.location
  name      = "${replace(var.project_name, "-", "")}replicationvault"
  parent_id = data.azurerm_resource_group.this.id
  type      = "Microsoft.DataReplication/replicationVaults@2024-09-01"
  body = {
    properties = {}
  }
  create_headers = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  delete_headers = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  read_headers   = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  tags = merge(var.tags, {
    "Migrate Project" = var.project_name
  })
  update_headers = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null

  identity {
    type = "SystemAssigned"
  }
}

# Get existing replication vault (from solution)
data "azapi_resource" "replication_vault" {
  count = local.vault_exists_in_solution ? 1 : 0

  resource_id = try(data.azapi_resource.replication_solution[0].output.properties.details.extendedDetails.vaultId, "")
  type        = "Microsoft.DataReplication/replicationVaults@2024-09-01"
}

# Query replication fabrics
data "azapi_resource_list" "replication_fabrics" {
  count = local.is_initialize_mode ? 1 : 0

  parent_id = data.azurerm_resource_group.this.id
  type      = "Microsoft.DataReplication/replicationFabrics@2024-09-01"

  depends_on = [azapi_resource.replication_vault]
}

# Query source fabric agents (DRAs) for role assignments
# CLI: get_fabric_agent() retrieves agents from {fabric}/fabricAgents endpoint
# Note: Uses has_fabric_inputs since resolved_fabric_id is computed at apply time
data "azapi_resource_list" "source_fabric_agents" {
  count = local.is_initialize_mode && local.has_fabric_inputs ? 1 : 0

  parent_id              = local.resolved_source_fabric_id
  type                   = "Microsoft.DataReplication/replicationFabrics/fabricAgents@2024-09-01"
  response_export_values = ["*"]

  depends_on = [data.azapi_resource_list.replication_fabrics]
}

# Query target fabric agents (DRAs) for role assignments
data "azapi_resource_list" "target_fabric_agents" {
  count = local.is_initialize_mode && local.has_fabric_inputs ? 1 : 0

  parent_id              = local.resolved_target_fabric_id
  type                   = "Microsoft.DataReplication/replicationFabrics/fabricAgents@2024-09-01"
  response_export_values = ["*"]

  depends_on = [data.azapi_resource_list.replication_fabrics]
}

# Create or update replication policy
resource "azapi_resource" "replication_policy" {
  count = local.is_initialize_mode ? 1 : 0

  name      = var.policy_name != null ? var.policy_name : "${split("/", local.create_new_vault ? azapi_resource.replication_vault[0].id : data.azapi_resource.replication_vault[0].id)[8]}${var.instance_type}policy"
  parent_id = local.create_new_vault ? azapi_resource.replication_vault[0].id : data.azapi_resource.replication_vault[0].id
  type      = "Microsoft.DataReplication/replicationVaults/replicationPolicies@2024-09-01"
  body = {
    properties = {
      customProperties = {
        instanceType                      = var.instance_type
        recoveryPointHistoryInMinutes     = var.recovery_point_history_minutes
        crashConsistentFrequencyInMinutes = var.crash_consistent_frequency_minutes
        appConsistentFrequencyInMinutes   = var.app_consistent_frequency_minutes
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

# Create cache storage account if not provided
resource "azurerm_storage_account" "cache" {
  count = local.is_initialize_mode && var.cache_storage_account_id == null ? 1 : 0

  account_replication_type         = "LRS"
  account_tier                     = "Standard"
  location                         = data.azurerm_resource_group.this.location
  name                             = local.storage_account_name
  resource_group_name              = data.azurerm_resource_group.this.name
  account_kind                     = "StorageV2"
  allow_nested_items_to_be_public  = false
  cross_tenant_replication_enabled = true
  min_tls_version                  = "TLS1_2"
  tags = merge(var.tags, {
    "Migrate Project" = var.project_name
  })

  blob_properties {
    versioning_enabled = false
  }
  network_rules {
    default_action = "Allow"
  }
}

# Grant Contributor role to vault identity on storage account
resource "azurerm_role_assignment" "vault_storage_contributor" {
  count = local.is_initialize_mode ? 1 : 0

  principal_id                     = local.create_new_vault ? azapi_resource.replication_vault[0].identity[0].principal_id : data.azapi_resource.replication_vault[0].output.identity.principalId
  scope                            = var.cache_storage_account_id != null ? var.cache_storage_account_id : azurerm_storage_account.cache[0].id
  role_definition_name             = "Contributor"
  skip_service_principal_aad_check = true
}

# Grant Storage Blob Data Contributor role to vault identity
resource "azurerm_role_assignment" "vault_storage_blob_contributor" {
  count = local.is_initialize_mode ? 1 : 0

  principal_id                     = local.create_new_vault ? azapi_resource.replication_vault[0].identity[0].principal_id : data.azapi_resource.replication_vault[0].output.identity.principalId
  scope                            = var.cache_storage_account_id != null ? var.cache_storage_account_id : azurerm_storage_account.cache[0].id
  role_definition_name             = "Storage Blob Data Contributor"
  skip_service_principal_aad_check = true
}

# ========================================
# DRA (Fabric Agent) Role Assignments
# CLI: grant_storage_permissions() grants both Contributor and Storage Blob Data Contributor
#      to source_dra, target_dra, and vault identity
# Note: These use has_fabric_inputs for count (known at plan time) and rely on
#       depends_on to ensure DRA data is available before the role assignment.
#       If DRA lookup fails, the principal_id will be null and Terraform will error,
#       which is the expected behavior (matching CLI's error for disconnected appliances).
# ========================================

# Grant Contributor role to source DRA identity
resource "azurerm_role_assignment" "source_dra_storage_contributor" {
  count = local.is_initialize_mode && local.has_fabric_inputs ? 1 : 0

  principal_id                     = local.source_dra_object_id
  scope                            = var.cache_storage_account_id != null ? var.cache_storage_account_id : azurerm_storage_account.cache[0].id
  role_definition_name             = "Contributor"
  skip_service_principal_aad_check = true

  depends_on = [data.azapi_resource_list.source_fabric_agents]
}

# Grant Storage Blob Data Contributor role to source DRA identity
resource "azurerm_role_assignment" "source_dra_storage_blob_contributor" {
  count = local.is_initialize_mode && local.has_fabric_inputs ? 1 : 0

  principal_id                     = local.source_dra_object_id
  scope                            = var.cache_storage_account_id != null ? var.cache_storage_account_id : azurerm_storage_account.cache[0].id
  role_definition_name             = "Storage Blob Data Contributor"
  skip_service_principal_aad_check = true

  depends_on = [data.azapi_resource_list.source_fabric_agents]
}

# Grant Contributor role to target DRA identity
resource "azurerm_role_assignment" "target_dra_storage_contributor" {
  count = local.is_initialize_mode && local.has_fabric_inputs ? 1 : 0

  principal_id                     = local.target_dra_object_id
  scope                            = var.cache_storage_account_id != null ? var.cache_storage_account_id : azurerm_storage_account.cache[0].id
  role_definition_name             = "Contributor"
  skip_service_principal_aad_check = true

  depends_on = [data.azapi_resource_list.target_fabric_agents]
}

# Grant Storage Blob Data Contributor role to target DRA identity
resource "azurerm_role_assignment" "target_dra_storage_blob_contributor" {
  count = local.is_initialize_mode && local.has_fabric_inputs ? 1 : 0

  principal_id                     = local.target_dra_object_id
  scope                            = var.cache_storage_account_id != null ? var.cache_storage_account_id : azurerm_storage_account.cache[0].id
  role_definition_name             = "Storage Blob Data Contributor"
  skip_service_principal_aad_check = true

  depends_on = [data.azapi_resource_list.target_fabric_agents]
}

# Wait for role assignments to propagate (CLI waits 120 seconds after grant_storage_permissions)
resource "time_sleep" "wait_for_role_propagation" {
  count = local.is_initialize_mode ? 1 : 0

  create_duration = "120s"

  depends_on = [
    azurerm_role_assignment.vault_storage_contributor,
    azurerm_role_assignment.vault_storage_blob_contributor,
    azurerm_role_assignment.source_dra_storage_contributor,
    azurerm_role_assignment.source_dra_storage_blob_contributor,
    azurerm_role_assignment.target_dra_storage_contributor,
    azurerm_role_assignment.target_dra_storage_blob_contributor
  ]
}

# Update AMH solution with storage account ID and vault ID
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
            replicationStorageAccountId = var.cache_storage_account_id != null ? var.cache_storage_account_id : azurerm_storage_account.cache[0].id
            vaultId                     = local.create_new_vault ? azapi_resource.replication_vault[0].id : data.azapi_resource.replication_vault[0].id
          }
        )
      }
    }
  }
  read_headers   = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  update_headers = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null

  depends_on = [
    azapi_resource.replication_vault,
    time_sleep.wait_for_role_propagation
  ]
}

# Wait for AMH solution update to propagate (CLI waits 60 seconds after update_amh_solution_storage)
resource "time_sleep" "wait_for_solution_update" {
  count = local.is_initialize_mode ? 1 : 0

  create_duration = "60s"

  depends_on = [
    azapi_update_resource.update_solution_storage
  ]
}

# Wait for all prerequisites to be ready before creating extension
# This matches the CLI behavior which waits 30 seconds after verify_extension_prerequisites
resource "time_sleep" "wait_for_solution_sync" {
  count = local.is_initialize_mode && local.has_fabric_inputs ? 1 : 0

  create_duration = "30s"

  depends_on = [
    time_sleep.wait_for_solution_update,
    azapi_resource.replication_policy
  ]
}

# Create replication extension
resource "azapi_resource" "replication_extension" {
  count = local.is_initialize_mode && local.has_fabric_inputs ? 1 : 0

  name      = "${basename(local.resolved_source_fabric_id)}-${basename(local.resolved_target_fabric_id)}-MigReplicationExtn"
  parent_id = local.create_new_vault ? azapi_resource.replication_vault[0].id : data.azapi_resource.replication_vault[0].id
  type      = "Microsoft.DataReplication/replicationVaults/replicationExtensions@2024-09-01"
  body = {
    properties = {
      customProperties = var.instance_type == "VMwareToAzStackHCI" ? {
        azStackHciFabricArmId       = local.resolved_target_fabric_id
        storageAccountId            = var.cache_storage_account_id != null ? var.cache_storage_account_id : azurerm_storage_account.cache[0].id
        storageAccountSasSecretName = null
        instanceType                = var.instance_type
        vmwareFabricArmId           = local.resolved_source_fabric_id
        } : {
        azStackHciFabricArmId       = local.resolved_target_fabric_id
        storageAccountId            = var.cache_storage_account_id != null ? var.cache_storage_account_id : azurerm_storage_account.cache[0].id
        storageAccountSasSecretName = null
        instanceType                = var.instance_type
        hyperVFabricArmId           = local.resolved_source_fabric_id
      }
    }
  }
  create_headers            = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  delete_headers            = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  read_headers              = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  schema_validation_enabled = false
  update_headers            = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null

  # Use shorter retry intervals
  retry = {
    error_message_regex  = ["RetryableError", "InternalServerError", "RequestTimeout"]
    interval_seconds     = 10
    max_interval_seconds = 30
    randomization_factor = 0.5
  }

  timeouts {
    create = "10m" # CLI waits up to 10 minutes (20 x 30s polling intervals)
    delete = "5m"
    read   = "2m"
  }

  lifecycle {
    # Prevent unnecessary recreation when changing between projects
    create_before_destroy = true
    # Ignore changes to body as updates often fail on this resource once created
    ignore_changes = [body]
  }

  depends_on = [
    time_sleep.wait_for_solution_sync
  ]
}

# ========================================
# CREATE SERVER REPLICATION
# ========================================

# Get discovered machine details (if machine_id provided)
# Note: This data source is currently not used and disabled to avoid lookup failures
data "azapi_resource" "discovered_machine" {
  count = 0 # Disabled: local.is_replicate_mode && var.machine_id != null ? 1 : 0

  resource_id = var.machine_id
  type        = contains(split("/", lower(var.machine_id)), "migrateprojects") ? "Microsoft.Migrate/migrateprojects/machines@2020-05-01" : (contains(split("/", lower(var.machine_id)), "hypervsites") ? "Microsoft.OffAzure/HyperVSites/machines@2023-06-06" : "Microsoft.OffAzure/VMwareSites/machines@2023-06-06")
}

# Create protected item (VM replication)
resource "azapi_resource" "protected_item" {
  count = local.is_replicate_mode && (var.machine_id != null || var.machine_name != null) ? 1 : 0

  name      = var.machine_name != null ? var.machine_name : basename(var.machine_id)
  parent_id = var.replication_vault_id
  type      = "Microsoft.DataReplication/replicationVaults/protectedItems@2024-09-01"
  body = {
    properties = {
      policyName               = var.policy_name
      replicationExtensionName = var.replication_extension_name
      customProperties = {
        instanceType                     = var.instance_type
        targetArcClusterCustomLocationId = var.custom_location_id
        customLocationRegion             = coalesce(var.location, data.azurerm_resource_group.this.location)
        fabricDiscoveryMachineId         = var.machine_id != null ? var.machine_id : "${data.azapi_resource.migrate_project[0].id}/machines/${var.machine_name}"
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
            diskSizeGB             = 60
            diskFileFormat         = "VHDX"
            isOsDisk               = true
            isDynamic              = true
            diskPhysicalSectorSize = 512
        }] : []
        targetVmName            = var.target_vm_name
        targetResourceGroupId   = var.target_resource_group_id
        storageContainerId      = var.target_storage_path_id
        hyperVGeneration        = var.hyperv_generation
        targetCpuCores          = var.target_vm_cpu_cores
        sourceCpuCores          = var.source_vm_cpu_cores
        isDynamicRam            = var.is_dynamic_memory_enabled
        sourceMemoryInMegaBytes = tonumber(var.source_vm_ram_mb)
        targetMemoryInMegaBytes = tonumber(var.target_vm_ram_mb)
        nicsToInclude = [
          for nic in var.nics_to_include : {
            nicId                    = nic.nic_id
            selectionTypeForFailover = nic.selection_type
            targetNetworkId          = nic.target_network_id
            testNetworkId            = nic.test_network_id != null ? nic.test_network_id : ""
          }
        ]
        dynamicMemoryConfig = {
          maximumMemoryInMegaBytes     = 1048576
          minimumMemoryInMegaBytes     = 512
          targetMemoryBufferPercentage = 20
        }
        sourceFabricAgentName = var.source_fabric_agent_name
        targetFabricAgentName = var.target_fabric_agent_name
        runAsAccountId        = var.run_as_account_id
        targetHCIClusterId    = var.target_hci_cluster_id
      }
    }
  }
  create_headers            = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  delete_headers            = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  read_headers              = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  ignore_missing_property   = true
  schema_validation_enabled = false
  update_headers            = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  response_export_values    = ["*"]
  locks                     = []

  timeouts {
    create = "5m"
    update = "5m"
    read   = "10m"
  }

  lifecycle {
    ignore_changes = [
      body
    ]
  }
}

# ========================================
#  GET REPLICATION JOBS
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
# GET PROTECTED ITEM OPERATION
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
# LIST PROTECTED ITEMS OPERATION
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
# AVM REQUIRED INTERFACES
# ========================================

resource "azurerm_management_lock" "this" {
  count = var.lock != null ? 1 : 0

  lock_level = var.lock.kind
  name       = coalesce(var.lock.name, "lock-${var.lock.kind}")
  scope      = data.azurerm_resource_group.this.id
  notes      = var.lock.kind == "CanNotDelete" ? "Cannot delete the resource or its child resources." : "Cannot delete or modify the resource or its child resources."
}

resource "azurerm_role_assignment" "this" {
  for_each = var.role_assignments

  principal_id                           = each.value.principal_id
  scope                                  = data.azurerm_resource_group.this.id
  condition                              = each.value.condition
  condition_version                      = each.value.condition_version
  delegated_managed_identity_resource_id = each.value.delegated_managed_identity_resource_id
  principal_type                         = each.value.principal_type
  role_definition_id                     = strcontains(lower(each.value.role_definition_id_or_name), lower(local.role_definition_resource_substring)) ? each.value.role_definition_id_or_name : null
  role_definition_name                   = strcontains(lower(each.value.role_definition_id_or_name), lower(local.role_definition_resource_substring)) ? null : each.value.role_definition_id_or_name
  skip_service_principal_aad_check       = each.value.skip_service_principal_aad_check
}
