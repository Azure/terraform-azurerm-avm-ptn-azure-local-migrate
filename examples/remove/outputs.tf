output "force_removal_status" {
  description = "Status of the force removal operation"
  value       = module.force_remove_replication.removal_status
}

output "operation_headers" {
  description = "Response headers with job tracking information"
  value       = module.remove_replication.removal_operation_headers
}

output "protected_item_info" {
  description = "Information about the protected item before removal"
  value       = module.remove_replication.protected_item_details
}

output "removal_job_details" {
  description = "Details of the removal job"
  value       = length(module.track_removal_job) > 0 ? module.track_removal_job[0].replication_job : null
}

output "removal_job_name" {
  description = "Name of the removal job for tracking"
  value       = local.job_name
}

output "removal_status" {
  description = "Status of the removal operation"
  value       = module.remove_replication.removal_status
}
