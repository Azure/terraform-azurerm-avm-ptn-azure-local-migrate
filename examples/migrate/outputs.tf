# Outputs
output "migration_operation_details" {
  description = "Detailed response from the migration operation including status and properties"
  value       = module.migrate_vm.migration_operation_details
}

output "migration_protected_item_details" {
  description = "Details of the protected item before migration including state and health"
  value       = module.migrate_vm.migration_protected_item_details
}

output "protected_item_id" {
  description = "ID of the protected item being migrated"
  value       = var.target_object_id
}
