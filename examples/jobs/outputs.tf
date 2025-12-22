# List all jobs
output "all_jobs" {
  description = "All replication jobs"
  value       = module.list_all_jobs.replication_jobs
}

# Specific job details
output "job_details" {
  description = "Details of the specific job"
  value       = module.get_specific_job.replication_job
}

output "jobs_count" {
  description = "Total number of jobs"
  value       = module.list_all_jobs.replication_jobs_count
}
