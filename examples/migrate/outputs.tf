output "async_operation_url" {
  description = "Async operation URL for tracking migration progress"
  value       = try(module.migrate_with_shutdown.migration_operation_details.headers["Azure-AsyncOperation"], "N/A")
}

output "migration_details" {
  description = "Detailed migration operation information"
  value = {
    protected_item_id   = module.migrate_with_shutdown.migration_status.protected_item_id
    source_vm           = module.migrate_with_shutdown.migration_status.source_machine_name
    target_vm           = module.migrate_with_shutdown.migration_status.target_vm_name
    shutdown_configured = module.migrate_with_shutdown.migration_status.shutdown_source_vm
    status              = module.migrate_with_shutdown.migration_status.operation_status
  }
}

output "migration_readiness_check" {
  description = "Pre-migration readiness assessment"
  value = {
    vm_name            = module.migrate_with_shutdown.migration_protected_item_details.name
    protection_state   = module.migrate_with_shutdown.migration_protected_item_details.protection_state
    replication_health = module.migrate_with_shutdown.migration_protected_item_details.replication_health
    can_migrate        = module.migrate_with_shutdown.migration_protected_item_details.can_perform_migration
    allowed_operations = module.migrate_with_shutdown.migration_protected_item_details.allowed_jobs
    warnings_count     = length(module.migrate_with_shutdown.migration_validation_warnings)
    is_ready_for_migration = (
      module.migrate_with_shutdown.migration_protected_item_details.can_perform_migration &&
      module.migrate_with_shutdown.migration_protected_item_details.replication_health == "Normal" &&
      length(module.migrate_with_shutdown.migration_validation_warnings) == 0
    )
  }
}

output "migration_status" {
  description = "Status of the migration operation"
  value       = module.migrate_with_shutdown.migration_status
}

output "migration_status_no_shutdown" {
  description = "Status of migration without shutdown"
  value       = module.migrate_without_shutdown.migration_status
}

output "protected_item_info" {
  description = "Information about the protected item before migration"
  value       = module.migrate_with_shutdown.migration_protected_item_details
}

output "validation_warnings" {
  description = "Any warnings detected before migration"
  value       = module.migrate_with_shutdown.migration_validation_warnings
}
