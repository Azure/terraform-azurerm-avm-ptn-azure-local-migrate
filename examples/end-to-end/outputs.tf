# ========================================
# STEP 1: REPLICATION OUTPUTS
# ========================================

output "protected_item_id" {
  description = "ID of the protected item (replicated VM)"
  value       = local.protected_item_id
}

output "target_vm_name" {
  description = "Name of the target VM on Azure Stack HCI"
  value       = module.replicate_vm.target_vm_name_output
}

# ========================================
# STEP 2: STATUS OUTPUTS
# ========================================

output "replication_status" {
  description = "Current replication status - wait for 'Protected' before migrating"
  value = {
    protection_state = try(module.check_status.protected_item_summary.protection_state, "Unknown")
    description      = try(module.check_status.protected_item_summary.protection_state_description, "Checking...")
    health           = try(module.check_status.protected_item_summary.replication_health, "Unknown")
    allowed_jobs     = try(module.check_status.protected_item_summary.allowed_jobs, [])
    ready_to_migrate = try(contains(module.check_status.protected_item_summary.allowed_jobs, "PlannedFailover"), false)
  }
}

output "next_step" {
  description = "Guidance on what to do next"
  value = try(
    contains(module.check_status.protected_item_summary.allowed_jobs, "PlannedFailover"),
    false
    ) ? "READY: Run 'terraform apply -var=\"perform_migration=true\"' to start migration" : (
    try(module.check_status.protected_item_summary.protection_state, "") == "InitialReplicationInProgress"
    ? "WAITING: Initial replication in progress. Re-run 'terraform apply' to check status."
    : "WAITING: Current state: ${try(module.check_status.protected_item_summary.protection_state, "Unknown")}. Re-run 'terraform apply' to refresh."
  )
}

# ========================================
# STEP 3: MIGRATION OUTPUTS (when perform_migration = true)
# ========================================

output "migration_triggered" {
  description = "Whether migration was triggered in this apply"
  value       = var.perform_migration
}

output "migration_operation_details" {
  description = "Details of the migration operation (only populated when perform_migration = true)"
  value       = var.perform_migration && length(module.migrate_vm) > 0 ? module.migrate_vm[0].migration_operation_details : null
}

output "migration_protected_item_details" {
  description = "Protected item details at time of migration (only populated when perform_migration = true)"
  value       = var.perform_migration && length(module.migrate_vm) > 0 ? module.migrate_vm[0].migration_protected_item_details : null
}
