output "protected_item_custom_properties" {
  description = "Custom properties of the protected item"
  value       = module.get_protected_item.protected_item_custom_properties
}

output "protected_item_health_errors" {
  description = "Health errors for the protected item"
  value       = module.get_protected_item.protected_item_health_errors
}

output "protected_item_id" {
  description = "The ID of the protected item"
  value       = module.get_protected_item.protected_item_id
}

output "protected_item_summary" {
  description = "Summary of the protected item"
  value       = module.get_protected_item.protected_item_summary
}

output "replication_state" {
  description = "The replication state of the protected item"
  value       = module.get_protected_item.replication_state
}
