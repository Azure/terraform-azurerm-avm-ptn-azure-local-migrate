# ========================================
# STEP 0: INITIALIZE OUTPUTS
# ========================================

# ========================================
# STEP 1: REPLICATION OUTPUTS
# ========================================

# ========================================
# STEP 2: STATUS OUTPUTS
# ========================================

# ========================================
# STEP 3: MIGRATION OUTPUTS
# ========================================

output "cache_storage_account_id" {
  description = "ID of the cache storage account (only when initialize runs)"
  value       = var.skip_initialize ? null : try(module.initialize[0].cache_storage_account_id, null)
}

output "migration_operation_details" {
  description = "Details of the migration operation per VM"
  value = {
    for key, vm in module.migrate_vm : key => vm.migration_operation_details
  }
}

output "migration_protected_item_details" {
  description = "Protected item details at time of migration per VM"
  value = {
    for key, vm in module.migrate_vm : key => vm.migration_protected_item_details
  }
}

output "protected_item_ids" {
  description = "Map of VM name to protected item ID (replicated VM)"
  value       = local.protected_item_ids
}

output "replication_extension_name" {
  description = "Name of the replication extension (from initialize or variable)"
  value       = local.replication_extension_name
}

output "replication_policy_name" {
  description = "Name of the replication policy (from initialize or variable)"
  value       = local.policy_name
}

output "replication_status" {
  description = "Current replication status per VM - wait for 'Protected' before migrating"
  value = {
    for key, status in module.check_status : key => {
      protection_state = try(status.protected_item_summary.protection_state, "Unknown")
      description      = try(status.protected_item_summary.protection_state_description, "Checking...")
      health           = try(status.protected_item_summary.replication_health, "Unknown")
      allowed_jobs     = try(status.protected_item_summary.allowed_jobs, [])
      ready_to_migrate = try(contains(status.protected_item_summary.allowed_jobs, "PlannedFailover"), false)
    }
  }
}

output "replication_vault_id" {
  description = "ID of the replication vault (from initialize or variable)"
  value       = local.replication_vault_id
}

output "target_vm_names" {
  description = "Map of VM name to target VM name on Azure Stack HCI"
  value = {
    for key, vm in module.replicate_vm : key => vm.target_vm_name_output
  }
}
