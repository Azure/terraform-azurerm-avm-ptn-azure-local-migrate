# Derived outputs for common queries
output "healthy_items_count" {
  description = "Count of items with Normal health"
  value = try(length([
    for item in module.list_protected_items.protected_items_summary :
    item.name if item.replication_health == "Normal"
  ]), 0)
}

output "items_needing_attention_count" {
  description = "Count of items with health errors"
  value = try(length([
    for item in module.list_protected_items.protected_items_summary :
    item.name if item.health_errors_count > 0
  ]), 0)
}

output "items_ready_for_migrate" {
  description = "Items that can perform planned failover (migration)"
  value = try([
    for item in module.list_protected_items.protected_items_summary :
    item.name if contains(item.allowed_jobs, "PlannedFailover")
  ], [])
}

output "items_requiring_resync" {
  description = "Items that require resynchronization"
  value = try([
    for item in module.list_protected_items.protected_items_summary :
    item.name if item.resynchronization_required
  ], [])
}

output "protected_items_by_health" {
  description = "Protected items grouped by replication health"
  value       = module.list_protected_items.protected_items_by_health
}

output "protected_items_by_state" {
  description = "Protected items grouped by protection state"
  value       = module.list_protected_items.protected_items_by_state
}

output "protected_items_count" {
  description = "Total number of protected items"
  value       = module.list_protected_items.protected_items_count
}

output "protected_items_summary" {
  description = "Summary of all protected items with key details"
  value       = module.list_protected_items.protected_items_summary
}

output "protected_items_with_errors" {
  description = "Protected items that have health errors"
  value       = module.list_protected_items.protected_items_with_errors
}
