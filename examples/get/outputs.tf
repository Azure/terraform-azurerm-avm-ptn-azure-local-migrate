output "protected_item_by_id_health" {
  description = "Health errors for protected item retrieved by ID"
  value       = module.get_by_id.protected_item_health_errors
}

# Example 1 outputs
output "protected_item_by_id_summary" {
  description = "Summary of protected item retrieved by ID"
  value       = module.get_by_id.protected_item_summary
}

output "protected_item_by_name_full" {
  description = "Full details of protected item retrieved by name"
  value       = module.get_by_name.protected_item
}

# Example 2 outputs
output "protected_item_by_name_summary" {
  description = "Summary of protected item retrieved by name"
  value       = module.get_by_name.protected_item_summary
}

output "protected_item_with_vault_allowed_operations" {
  description = "Allowed operations on protected item"
  value       = try(module.get_with_vault.protected_item_summary.allowed_jobs, [])
}

# Example 3 outputs
output "protected_item_with_vault_custom_properties" {
  description = "Custom properties of protected item"
  value       = module.get_with_vault.protected_item_custom_properties
}
