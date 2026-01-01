# --------------------------------------------------------------------------------------------
# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License. See License.txt in the project root for license information.
# --------------------------------------------------------------------------------------------

# ========================================
# DISCOVERY COMMAND OUTPUTS
# ========================================

# ========================================
# INITIALIZE INFRASTRUCTURE OUTPUTS
# ========================================

# ========================================
# CREATE REPLICATION OUTPUTS
# ========================================

# ========================================
# GENERAL OUTPUTS
# ========================================

# ========================================
# JOBS COMMAND OUTPUTS
# ========================================

# ========================================
# COMMAND 5: REMOVE REPLICATION OUTPUTS
# ========================================

# ========================================
# GET PROTECTED ITEM OUTPUTS
# ========================================

# ========================================
# LIST PROTECTED ITEMS OUTPUTS
# ========================================

# ========================================
# MIGRATE (PLANNED FAILOVER) OUTPUTS
# ========================================

output "cache_storage_account_id" {
  description = "ID of the cache storage account"
  value       = local.is_initialize_mode ? (var.cache_storage_account_id != null ? var.cache_storage_account_id : (length(azurerm_storage_account.cache) > 0 ? azurerm_storage_account.cache[0].id : null)) : null
}

output "cache_storage_account_name" {
  description = "Name of the cache storage account"
  value       = local.is_initialize_mode && length(azurerm_storage_account.cache) > 0 ? azurerm_storage_account.cache[0].name : null
}

# Debug output - data source length
output "debug_data_source_length" {
  description = "Length of discovered_servers data source"
  value       = length(data.azapi_resource_list.discovered_servers)
}

# Debug output - check mode
output "debug_is_discover_mode" {
  description = "Is discover mode active"
  value       = local.is_discover_mode
}

# Debug output - parsed servers
output "debug_parsed_servers" {
  description = "Parsed servers for debugging"
  value       = local.is_discover_mode && length(data.azapi_resource_list.discovered_servers) > 0 ? try(data.azapi_resource_list.discovered_servers[0].output.value, []) : []
}

# Debug output - raw API response
output "debug_raw_discovered_servers" {
  description = "Raw API response for debugging"
  value       = local.is_discover_mode && length(data.azapi_resource_list.discovered_servers) > 0 ? data.azapi_resource_list.discovered_servers[0].output : null
}

output "discovered_servers" {
  description = "List of discovered servers from Azure Migrate (filtered: index, machine_name, ip_addresses, operating_system, boot_type, os_disk_id)"
  value = local.is_discover_mode && length(data.azapi_resource_list.discovered_servers) > 0 ? [
    for idx, server in try(data.azapi_resource_list.discovered_servers[0].output.value, []) : {
      index            = idx + 1
      machine_name     = try(server.properties.discoveryData[0].machineName, server.properties.discoveryData[0].fqdn, server.name, "N/A")
      ip_addresses     = try(length(server.properties.discoveryData[0].ipAddresses) > 0 ? join(", ", server.properties.discoveryData[0].ipAddresses) : "None", "N/A")
      operating_system = try(server.properties.discoveryData[0].osName, "N/A")
      boot_type        = try(server.properties.discoveryData[0].extendedInfo.bootType, "N/A")
      os_disk_id       = try(jsondecode(server.properties.discoveryData[0].extendedInfo.diskDetails)[0].InstanceId, "N/A")
    } if try(length(server.properties.discoveryData), 0) > 0
  ] : []
}

output "discovered_servers_count" {
  description = "Total number of discovered servers with discovery data"
  value = local.is_discover_mode && length(data.azapi_resource_list.discovered_servers) > 0 ? length([
    for server in try(data.azapi_resource_list.discovered_servers[0].output.value, []) :
    server if try(length(server.properties.discoveryData), 0) > 0
  ]) : 0
}

output "location_output" {
  description = "Azure region where resources are deployed"
  value       = data.azurerm_resource_group.this.location
}

output "machine_id" {
  description = "Machine ID being replicated"
  value       = var.machine_id
}

output "migrate_project_id" {
  description = "Azure Migrate project ID"
  value       = length(data.azapi_resource.migrate_project) > 0 ? data.azapi_resource.migrate_project[0].id : null
}

output "migration_operation_details" {
  description = "Detailed response from the migration operation including async operation URL for job tracking"
  value = local.is_migrate_mode ? try(
    coalescelist(
      azapi_resource_action.planned_failover_hyperv[*].output,
      azapi_resource_action.planned_failover_vmware[*].output
    )[0],
    null
  ) : null
}

output "migration_protected_item_details" {
  description = "Details of the protected item being migrated (before migration)"
  value = local.is_migrate_mode && length(data.azapi_resource.protected_item_to_migrate) > 0 ? {
    name                     = try(data.azapi_resource.protected_item_to_migrate[0].output.name, "N/A")
    protection_state         = try(data.azapi_resource.protected_item_to_migrate[0].output.properties.protectionState, "Unknown")
    protection_description   = try(data.azapi_resource.protected_item_to_migrate[0].output.properties.protectionStateDescription, "N/A")
    replication_health       = try(data.azapi_resource.protected_item_to_migrate[0].output.properties.replicationHealth, "Unknown")
    allowed_jobs             = try(data.azapi_resource.protected_item_to_migrate[0].output.properties.allowedJobs, [])
    can_perform_migration    = try(contains(data.azapi_resource.protected_item_to_migrate[0].output.properties.allowedJobs, "PlannedFailover") || contains(data.azapi_resource.protected_item_to_migrate[0].output.properties.allowedJobs, "Restart"), false)
    instance_type            = try(data.azapi_resource.protected_item_to_migrate[0].output.properties.customProperties.instanceType, "N/A")
    source_machine_name      = try(data.azapi_resource.protected_item_to_migrate[0].output.properties.customProperties.sourceMachineName, "N/A")
    target_vm_name           = try(data.azapi_resource.protected_item_to_migrate[0].output.properties.customProperties.targetVmName, "N/A")
    target_resource_group_id = try(data.azapi_resource.protected_item_to_migrate[0].output.properties.customProperties.targetResourceGroupId, "N/A")
    target_hci_cluster_id    = try(data.azapi_resource.protected_item_to_migrate[0].output.properties.customProperties.targetHCIClusterId, "N/A")
  } : null
}

output "migration_status" {
  description = "Status of the migration (planned failover) operation"
  value = local.is_migrate_mode && (length(azapi_resource_action.planned_failover_hyperv) > 0 || length(azapi_resource_action.planned_failover_vmware) > 0) ? {
    protected_item_id   = var.protected_item_id
    shutdown_source_vm  = var.shutdown_source_vm
    operation_status    = "Initiated"
    message             = "Migration (planned failover) has been successfully initiated for '${var.protected_item_id}'"
    vm_name             = try(data.azapi_resource.protected_item_to_migrate[0].output.name, "N/A")
    source_machine_name = try(data.azapi_resource.protected_item_to_migrate[0].output.properties.customProperties.sourceMachineName, "N/A")
    target_vm_name      = try(data.azapi_resource.protected_item_to_migrate[0].output.properties.customProperties.targetVmName, "N/A")
  } : null
}

output "migration_validation_warnings" {
  description = "Validation warnings or issues detected before migration"
  value = local.is_migrate_mode && length(data.azapi_resource.protected_item_to_migrate) > 0 ? [
    for warning in concat(
      try(data.azapi_resource.protected_item_to_migrate[0].output.properties.healthErrors, []),
      try(data.azapi_resource.protected_item_to_migrate[0].output.properties.resynchronizationRequired, false) ? [{
        message  = "Resynchronization is required before migration"
        severity = "Warning"
      }] : []
      ) : {
      message  = try(warning.message, warning.message)
      severity = try(warning.severity, "Warning")
      code     = try(warning.errorCode, "N/A")
    }
  ] : []
}

output "operation_mode" {
  description = "Current operation mode"
  value       = var.operation_mode
}

output "project_name_output" {
  description = "Azure Migrate project name"
  value       = var.project_name
}

output "protected_item" {
  description = "Complete protected item details including replication status, health, and configuration"
  value = local.is_get_mode ? (
    var.protected_item_id != null && length(data.azapi_resource.protected_item_by_id) > 0 ?
    data.azapi_resource.protected_item_by_id[0].output :
    (var.protected_item_name != null && length(data.azapi_resource.protected_item_by_name) > 0 ?
    data.azapi_resource.protected_item_by_name[0].output : null)
  ) : null
}

output "protected_item_custom_properties" {
  description = "Custom properties including fabric-specific details, disk configuration, and network settings"
  value = local.is_get_mode ? (
    var.protected_item_id != null && length(data.azapi_resource.protected_item_by_id) > 0 ?
    try(data.azapi_resource.protected_item_by_id[0].output.properties.customProperties, {}) :
    (var.protected_item_name != null && length(data.azapi_resource.protected_item_by_name) > 0 ?
    try(data.azapi_resource.protected_item_by_name[0].output.properties.customProperties, {}) : {})
  ) : {}
}

output "protected_item_details" {
  description = "Details of the protected item before removal (for validation)"
  value = local.is_remove_mode && length(data.azapi_resource.protected_item_to_remove) > 0 ? {
    name                   = try(data.azapi_resource.protected_item_to_remove[0].output.name, "N/A")
    protection_state       = try(data.azapi_resource.protected_item_to_remove[0].output.properties.protectionStateDescription, "Unknown")
    allowed_jobs           = try(data.azapi_resource.protected_item_to_remove[0].output.properties.allowedJobs, [])
    can_disable_protection = try(contains(data.azapi_resource.protected_item_to_remove[0].output.properties.allowedJobs, "DisableProtection"), false)
    replication_health     = try(data.azapi_resource.protected_item_to_remove[0].output.properties.replicationHealth, "Unknown")
  } : null
}

output "protected_item_health_errors" {
  description = "List of health errors for the protected item"
  value = local.is_get_mode ? (
    var.protected_item_id != null && length(data.azapi_resource.protected_item_by_id) > 0 ?
    try(data.azapi_resource.protected_item_by_id[0].output.properties.healthErrors, []) :
    (var.protected_item_name != null && length(data.azapi_resource.protected_item_by_name) > 0 ?
    try(data.azapi_resource.protected_item_by_name[0].output.properties.healthErrors, []) : [])
  ) : []
}

output "protected_item_id" {
  description = "ID of the protected item (replicated VM)"
  value       = local.is_replicate_mode && length(azapi_resource.protected_item) > 0 ? azapi_resource.protected_item[0].id : null
}

output "protected_item_name" {
  description = "Name of the protected item"
  value       = local.is_replicate_mode && length(azapi_resource.protected_item) > 0 ? azapi_resource.protected_item[0].name : null
}

output "protected_item_summary" {
  description = "Summary of protected item with key information"
  value = local.is_get_mode ? (
    var.protected_item_id != null && length(data.azapi_resource.protected_item_by_id) > 0 ? {
      id                           = try(data.azapi_resource.protected_item_by_id[0].output.id, "N/A")
      name                         = try(data.azapi_resource.protected_item_by_id[0].output.name, "N/A")
      type                         = try(data.azapi_resource.protected_item_by_id[0].output.type, "N/A")
      protection_state             = try(data.azapi_resource.protected_item_by_id[0].output.properties.protectionState, "Unknown")
      protection_state_description = try(data.azapi_resource.protected_item_by_id[0].output.properties.protectionStateDescription, "N/A")
      replication_health           = try(data.azapi_resource.protected_item_by_id[0].output.properties.replicationHealth, "Unknown")
      policy_name                  = try(data.azapi_resource.protected_item_by_id[0].output.properties.policyName, "N/A")
      replication_extension_name   = try(data.azapi_resource.protected_item_by_id[0].output.properties.replicationExtensionName, "N/A")
      allowed_jobs                 = try(data.azapi_resource.protected_item_by_id[0].output.properties.allowedJobs, [])
      resynchronization_required   = try(data.azapi_resource.protected_item_by_id[0].output.properties.resynchronizationRequired, false)
      last_test_failover_time      = try(data.azapi_resource.protected_item_by_id[0].output.properties.lastSuccessfulTestFailoverTime, "N/A")
      last_test_failover_status    = try(data.azapi_resource.protected_item_by_id[0].output.properties.lastTestFailoverStatus, "N/A")
      last_planned_failover_time   = try(data.azapi_resource.protected_item_by_id[0].output.properties.lastSuccessfulPlannedFailoverTime, "N/A")
      last_unplanned_failover_time = try(data.azapi_resource.protected_item_by_id[0].output.properties.lastSuccessfulUnplannedFailoverTime, "N/A")
      source_machine_name          = try(data.azapi_resource.protected_item_by_id[0].output.properties.customProperties.sourceMachineName, "N/A")
      target_vm_name               = try(data.azapi_resource.protected_item_by_id[0].output.properties.customProperties.targetVmName, "N/A")
      target_resource_group_id     = try(data.azapi_resource.protected_item_by_id[0].output.properties.customProperties.targetResourceGroupId, "N/A")
      instance_type                = try(data.azapi_resource.protected_item_by_id[0].output.properties.customProperties.instanceType, "N/A")
      } : (
      var.protected_item_name != null && length(data.azapi_resource.protected_item_by_name) > 0 ? {
        id                           = try(data.azapi_resource.protected_item_by_name[0].output.id, "N/A")
        name                         = try(data.azapi_resource.protected_item_by_name[0].output.name, "N/A")
        type                         = try(data.azapi_resource.protected_item_by_name[0].output.type, "N/A")
        protection_state             = try(data.azapi_resource.protected_item_by_name[0].output.properties.protectionState, "Unknown")
        protection_state_description = try(data.azapi_resource.protected_item_by_name[0].output.properties.protectionStateDescription, "N/A")
        replication_health           = try(data.azapi_resource.protected_item_by_name[0].output.properties.replicationHealth, "Unknown")
        policy_name                  = try(data.azapi_resource.protected_item_by_name[0].output.properties.policyName, "N/A")
        replication_extension_name   = try(data.azapi_resource.protected_item_by_name[0].output.properties.replicationExtensionName, "N/A")
        allowed_jobs                 = try(data.azapi_resource.protected_item_by_name[0].output.properties.allowedJobs, [])
        resynchronization_required   = try(data.azapi_resource.protected_item_by_name[0].output.properties.resynchronizationRequired, false)
        last_test_failover_time      = try(data.azapi_resource.protected_item_by_name[0].output.properties.lastSuccessfulTestFailoverTime, "N/A")
        last_test_failover_status    = try(data.azapi_resource.protected_item_by_name[0].output.properties.lastTestFailoverStatus, "N/A")
        last_planned_failover_time   = try(data.azapi_resource.protected_item_by_name[0].output.properties.lastSuccessfulPlannedFailoverTime, "N/A")
        last_unplanned_failover_time = try(data.azapi_resource.protected_item_by_name[0].output.properties.lastSuccessfulUnplannedFailoverTime, "N/A")
        source_machine_name          = try(data.azapi_resource.protected_item_by_name[0].output.properties.customProperties.sourceMachineName, "N/A")
        target_vm_name               = try(data.azapi_resource.protected_item_by_name[0].output.properties.customProperties.targetVmName, "N/A")
        target_resource_group_id     = try(data.azapi_resource.protected_item_by_name[0].output.properties.customProperties.targetResourceGroupId, "N/A")
        instance_type                = try(data.azapi_resource.protected_item_by_name[0].output.properties.customProperties.instanceType, "N/A")
      } : null
    )
  ) : null
}

output "protected_items_by_health" {
  description = "Protected items grouped by replication health"
  value = local.is_list_mode && length(data.azapi_resource_list.protected_items) > 0 ? {
    for health in distinct([
      for item in try(data.azapi_resource_list.protected_items[0].output.value, []) :
      try(item.properties.replicationHealth, "Unknown")
      ]) : health => [
      for item in try(data.azapi_resource_list.protected_items[0].output.value, []) :
      try(item.name, "N/A") if try(item.properties.replicationHealth, "Unknown") == health
    ]
  } : {}
}

output "protected_items_by_state" {
  description = "Protected items grouped by protection state"
  value = local.is_list_mode && length(data.azapi_resource_list.protected_items) > 0 ? {
    for state in distinct([
      for item in try(data.azapi_resource_list.protected_items[0].output.value, []) :
      try(item.properties.protectionState, "Unknown")
      ]) : state => [
      for item in try(data.azapi_resource_list.protected_items[0].output.value, []) :
      try(item.name, "N/A") if try(item.properties.protectionState, "Unknown") == state
    ]
  } : {}
}

output "protected_items_count" {
  description = "Total number of protected items found"
  value       = local.is_list_mode && length(data.azapi_resource_list.protected_items) > 0 ? length(try(data.azapi_resource_list.protected_items[0].output.value, [])) : 0
}

output "protected_items_list" {
  description = "Complete list of all protected items (replicated VMs) in the vault"
  value       = local.is_list_mode && length(data.azapi_resource_list.protected_items) > 0 ? try(data.azapi_resource_list.protected_items[0].output.value, []) : []
}

output "protected_items_summary" {
  description = "Summary list with key information for each protected item"
  value = local.is_list_mode && length(data.azapi_resource_list.protected_items) > 0 ? [
    for item in try(data.azapi_resource_list.protected_items[0].output.value, []) : {
      name                         = try(item.name, "N/A")
      id                           = try(item.id, "N/A")
      protection_state             = try(item.properties.protectionState, "Unknown")
      protection_state_description = try(item.properties.protectionStateDescription, "N/A")
      replication_health           = try(item.properties.replicationHealth, "Unknown")
      source_machine_name          = try(item.properties.customProperties.sourceMachineName, "N/A")
      target_vm_name               = try(item.properties.customProperties.targetVmName, "N/A")
      target_resource_group_id     = try(item.properties.customProperties.targetResourceGroupId, "N/A")
      policy_name                  = try(item.properties.policyName, "N/A")
      replication_extension_name   = try(item.properties.replicationExtensionName, "N/A")
      instance_type                = try(item.properties.customProperties.instanceType, "N/A")
      allowed_jobs                 = try(item.properties.allowedJobs, [])
      health_errors_count          = try(length(item.properties.healthErrors), 0)
      resynchronization_required   = try(item.properties.resynchronizationRequired, false)
    }
  ] : []
}

output "protected_items_with_errors" {
  description = "List of protected items that have health errors"
  value = local.is_list_mode && length(data.azapi_resource_list.protected_items) > 0 ? [
    for item in try(data.azapi_resource_list.protected_items[0].output.value, []) : {
      name          = try(item.name, "N/A")
      health_errors = try(item.properties.healthErrors, [])
    } if try(length(item.properties.healthErrors), 0) > 0
  ] : []
}

output "removal_operation_headers" {
  description = "Response headers from the removal operation (includes Azure-AsyncOperation and Location for job tracking)"
  value       = local.is_remove_mode && length(azapi_resource_action.remove_replication) > 0 ? try(azapi_resource_action.remove_replication[0].output, null) : null
}

output "removal_status" {
  description = "Status of the replication removal operation"
  value = local.is_remove_mode && length(azapi_resource_action.remove_replication) > 0 ? {
    protected_item_id = var.target_object_id
    force_remove      = var.force_remove
    operation_status  = "Initiated"
    message           = "Successfully initiated removal of replication for protected item '${var.target_object_id}'"
  } : null
}

output "replication_extension_id" {
  description = "ID of the replication extension"
  value       = local.is_initialize_mode && length(azapi_resource.replication_extension) > 0 ? azapi_resource.replication_extension[0].id : null
}

output "replication_extension_name" {
  description = "Name of the replication extension"
  value       = local.is_initialize_mode && length(azapi_resource.replication_extension) > 0 ? azapi_resource.replication_extension[0].name : null
}

output "replication_job" {
  description = "Detailed information for a specific replication job"
  value = local.is_jobs_mode && var.job_name != null && length(data.azapi_resource.replication_job) > 0 ? {
    job_name     = try(data.azapi_resource.replication_job[0].output.name, "N/A")
    display_name = try(data.azapi_resource.replication_job[0].output.properties.displayName, "N/A")
    state        = try(data.azapi_resource.replication_job[0].output.properties.state, "N/A")
    vm_name      = try(data.azapi_resource.replication_job[0].output.properties.objectInternalName, "N/A")
    start_time   = try(data.azapi_resource.replication_job[0].output.properties.startTime, "N/A")
    end_time     = try(data.azapi_resource.replication_job[0].output.properties.endTime, null)
    errors = try([
      for error in data.azapi_resource.replication_job[0].output.properties.errors : {
        message        = try(error.message, "N/A")
        code           = try(error.code, "N/A")
        recommendation = try(error.recommendation, null)
      }
    ], [])
    tasks = try([
      for task in data.azapi_resource.replication_job[0].output.properties.tasks : {
        name       = try(task.taskName, "N/A")
        state      = try(task.state, "N/A")
        start_time = try(task.startTime, null)
        end_time   = try(task.endTime, null)
      }
    ], [])
  } : null
}

output "replication_jobs" {
  description = "Summary of all replication jobs in the vault"
  value = local.is_jobs_mode && var.job_name == null && length(data.azapi_resource_list.replication_jobs) > 0 ? [
    for job in try(data.azapi_resource_list.replication_jobs[0].output.value, []) : {
      job_name     = try(job.name, "N/A")
      display_name = try(job.properties.displayName, "N/A")
      state        = try(job.properties.state, "N/A")
      vm_name      = try(job.properties.objectInternalName, "N/A")
      start_time   = try(job.properties.startTime, "N/A")
      end_time     = try(job.properties.endTime, null)
      has_errors   = try(length(job.properties.errors) > 0, false)
    }
  ] : []
}

output "replication_jobs_count" {
  description = "Total number of replication jobs in the vault"
  value = local.is_jobs_mode && var.job_name == null && length(data.azapi_resource_list.replication_jobs) > 0 ? length(
    try(data.azapi_resource_list.replication_jobs[0].output.value, [])
  ) : 0
}

output "replication_policy_id" {
  description = "ID of the replication policy"
  value       = local.is_initialize_mode && length(azapi_resource.replication_policy) > 0 ? azapi_resource.replication_policy[0].id : null
}

output "replication_state" {
  description = "Current replication state"
  value       = local.is_replicate_mode && length(azapi_resource.protected_item) > 0 ? try(jsondecode(azapi_resource.protected_item[0].output).properties.replicationHealth, "Unknown") : null
}

output "replication_vault_id" {
  description = "ID of the replication vault"
  value       = local.is_initialize_mode ? (local.create_new_vault ? azapi_resource.replication_vault[0].id : data.azapi_resource.replication_vault[0].id) : null
}

output "replication_vault_identity" {
  description = "Managed identity of the replication vault"
  value       = local.is_initialize_mode ? (local.create_new_vault ? azapi_resource.replication_vault[0].identity[0].principal_id : data.azapi_resource.replication_vault[0].output.identity.principalId) : null
}

output "resource_group_name_output" {
  description = "Name of the resource group"
  value       = data.azurerm_resource_group.this.name
}

output "source_fabric_id" {
  description = "Source fabric ID used for replication"
  value       = var.source_fabric_id
}

output "target_fabric_id" {
  description = "Target fabric ID used for replication"
  value       = var.target_fabric_id
}

output "target_vm_name_output" {
  description = "Name of the target VM to be created"
  value       = var.target_vm_name
}

output "total_machines_count" {
  description = "Total number of machines (including those without discovery data)"
  value       = local.is_discover_mode && length(data.azapi_resource_list.discovered_servers) > 0 ? length(try(data.azapi_resource_list.discovered_servers[0].output.value, [])) : 0
}

output "vault_id_for_jobs" {
  description = "Replication vault ID used for job queries"
  value       = local.is_jobs_mode && length(data.azapi_resource.vault_for_jobs) > 0 ? data.azapi_resource.vault_for_jobs[0].id : null
}
