output "protected_item_details" {
  description = "Information about the protected item before removal"
  value       = module.remove_replication.protected_item_details
}

output "removal_operation_headers" {
  description = "Response headers from the removal operation (includes Azure-AsyncOperation and Location for job tracking)"
  value       = module.remove_replication.removal_operation_headers
}

output "removal_status" {
  description = "Status of the replication removal operation"
  value       = module.remove_replication.removal_status
}
