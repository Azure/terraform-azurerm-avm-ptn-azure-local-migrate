output "healthy_items_count" {
  description = "Count of items with Normal health"
  value = length([
    for item in module.list_by_project.protected_items_summary :
    item.name if item.replication_health == "Normal"
  ])
}

output "items_by_health" {
  description = "Protected items grouped by replication health"
  value       = module.list_by_project.protected_items_by_health
}

output "items_by_state" {
  description = "Protected items grouped by protection state"
  value       = module.list_by_project.protected_items_by_state
}

output "items_needing_attention_count" {
  description = "Count of items with health errors"
  value = length([
    for item in module.list_by_project.protected_items_summary :
    item.name if item.health_errors_count > 0
  ])
}

output "items_ready_for_migrate" {
  description = "Items that can perform migration"
  value = [
    for item in module.list_by_project.protected_items_summary :
    item.name if contains(item.allowed_jobs, "Migrate")
  ]
}

output "items_ready_for_test_migrate" {
  description = "Items that can perform test migration"
  value = [
    for item in module.list_by_project.protected_items_summary :
    item.name if contains(item.allowed_jobs, "TestMigrate")
  ]
}

output "items_requiring_resync" {
  description = "Items that require resynchronization"
  value = [
    for item in module.list_by_project.protected_items_summary :
    item.name if item.resynchronization_required
  ]
}

output "items_with_errors" {
  description = "Protected items that have health errors"
  value       = module.list_by_project.protected_items_with_errors
}

output "protected_items_summary" {
  description = "Summary of all protected items"
  value       = module.list_by_project.protected_items_summary
}

output "total_protected_items" {
  description = "Total number of replicated VMs"
  value       = module.list_by_project.protected_items_count
}

output "vault_protected_items_count" {
  description = "Number of protected items in vault"
  value       = module.list_by_vault.protected_items_count
}

output "vault_protected_items_names" {
  description = "Names of all protected items in vault"
  value       = [for item in module.list_by_vault.protected_items_summary : item.name]
}
