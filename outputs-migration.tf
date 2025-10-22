# --------------------------------------------------------------------------------------------
# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License. See License.txt in the project root for license information.
# --------------------------------------------------------------------------------------------

# ========================================
# DISCOVERY COMMAND OUTPUTS
# ========================================

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

output "total_machines_count" {
  description = "Total number of machines (including those without discovery data)"
  value = local.is_discover_mode && length(data.azapi_resource_list.discovered_servers) > 0 ? length(try(data.azapi_resource_list.discovered_servers[0].output.value, [])) : 0
}

# Debug output - raw API response
output "debug_raw_discovered_servers" {
  description = "Raw API response for debugging"
  value       = local.is_discover_mode && length(data.azapi_resource_list.discovered_servers) > 0 ? data.azapi_resource_list.discovered_servers[0].output : null
}

# Debug output - parsed servers
output "debug_parsed_servers" {
  description = "Parsed servers for debugging"
  value       = local.is_discover_mode && length(data.azapi_resource_list.discovered_servers) > 0 ? try(data.azapi_resource_list.discovered_servers[0].output.value, []) : []
}

# Debug output - check mode
output "debug_is_discover_mode" {
  description = "Is discover mode active"
  value       = local.is_discover_mode
}

# Debug output - data source length
output "debug_data_source_length" {
  description = "Length of discovered_servers data source"
  value       = length(data.azapi_resource_list.discovered_servers)
}

# ========================================
# INITIALIZE INFRASTRUCTURE OUTPUTS
# ========================================

output "replication_vault_id" {
  description = "ID of the replication vault"
  value       = local.is_initialize_mode ? (local.create_new_vault ? azapi_resource.replication_vault[0].id : data.azapi_resource.replication_vault[0].id) : null
}

output "replication_vault_identity" {
  description = "Managed identity of the replication vault"
  value       = local.is_initialize_mode ? (local.create_new_vault ? azapi_resource.replication_vault[0].identity[0].principal_id : data.azapi_resource.replication_vault[0].output.identity.principalId) : null
}

output "replication_policy_id" {
  description = "ID of the replication policy"
  value       = local.is_initialize_mode && length(azapi_resource.replication_policy) > 0 ? azapi_resource.replication_policy[0].id : null
}

output "cache_storage_account_id" {
  description = "ID of the cache storage account"
  value       = local.is_initialize_mode ? (var.cache_storage_account_id != null ? var.cache_storage_account_id : (length(azurerm_storage_account.cache) > 0 ? azurerm_storage_account.cache[0].id : null)) : null
}

output "cache_storage_account_name" {
  description = "Name of the cache storage account"
  value       = local.is_initialize_mode && length(azurerm_storage_account.cache) > 0 ? azurerm_storage_account.cache[0].name : null
}

output "replication_extension_id" {
  description = "ID of the replication extension"
  value       = local.is_initialize_mode && length(azapi_resource.replication_extension) > 0 ? azapi_resource.replication_extension[0].id : null
}

output "replication_extension_name" {
  description = "Name of the replication extension"
  value       = local.is_initialize_mode && length(azapi_resource.replication_extension) > 0 ? azapi_resource.replication_extension[0].name : null
}

output "source_fabric_id" {
  description = "Source fabric ID used for replication"
  value       = var.source_fabric_id
}

output "target_fabric_id" {
  description = "Target fabric ID used for replication"
  value       = var.target_fabric_id
}

# ========================================
# CREATE REPLICATION OUTPUTS
# ========================================

output "protected_item_id" {
  description = "ID of the protected item (replicated VM)"
  value       = local.is_replicate_mode && length(azapi_resource.protected_item) > 0 ? azapi_resource.protected_item[0].id : null
}

output "protected_item_name" {
  description = "Name of the protected item"
  value       = local.is_replicate_mode && length(azapi_resource.protected_item) > 0 ? azapi_resource.protected_item[0].name : null
}

output "replication_state" {
  description = "Current replication state"
  value       = local.is_replicate_mode && length(azapi_resource.protected_item) > 0 ? try(jsondecode(azapi_resource.protected_item[0].output).properties.replicationHealth, "Unknown") : null
}

output "machine_id" {
  description = "Machine ID being replicated"
  value       = var.machine_id
}

output "target_vm_name_output" {
  description = "Name of the target VM to be created"
  value       = var.target_vm_name
}

# ========================================
# GENERAL OUTPUTS
# ========================================

output "resource_group_name_output" {
  description = "Name of the resource group"
  value       = data.azurerm_resource_group.this.name
}

output "location_output" {
  description = "Azure region where resources are deployed"
  value       = data.azurerm_resource_group.this.location
}

output "project_name_output" {
  description = "Azure Migrate project name"
  value       = var.project_name
}

output "operation_mode" {
  description = "Current operation mode"
  value       = var.operation_mode
}

output "migrate_project_id" {
  description = "Azure Migrate project ID"
  value       = length(data.azapi_resource.migrate_project) > 0 ? data.azapi_resource.migrate_project[0].id : null
}
