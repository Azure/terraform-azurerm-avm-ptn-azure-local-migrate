output "replication_job" {
  description = "Details of a specific replication job (when job_name is provided, otherwise null)"
  value       = module.replication_jobs.replication_job
}

output "replication_jobs" {
  description = "All replication jobs in the vault (when job_name is null)"
  value       = module.replication_jobs.replication_jobs
}

output "replication_jobs_count" {
  description = "Total number of replication jobs (when listing all jobs)"
  value       = module.replication_jobs.replication_jobs_count
}
