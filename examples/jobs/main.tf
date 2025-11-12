# Example: Get Replication Jobs
# This example demonstrates how to retrieve replication job status

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.49.0"
    }
    azapi = {
      source  = "azure/azapi"
      version = ">= 2.7.0"
    }
  }
}

provider "azurerm" {
  features {}
}

provider "azapi" {}

# Example 1: List all jobs in a vault
module "list_all_jobs" {
  source = "../../"

  # Required
  name                = "migration-jobs-list"
  location            = "eastus"
  resource_group_name = "your-resource-group"

  # Operation mode
  operation_mode = "jobs"

  # Project details (to find vault from solution)
  project_name = "your-migrate-project"

  # Optional: Provide vault ID directly if known
  # replication_vault_id = "/subscriptions/xxx/resourceGroups/xxx/providers/Microsoft.DataReplication/replicationVaults/xxx"
}

# Example 2: Get a specific job by name
module "get_specific_job" {
  source = "../../"

  # Required
  name                = "migration-job-detail"
  location            = "eastus"
  resource_group_name = "your-resource-group"

  # Operation mode
  operation_mode = "jobs"

  # Job to retrieve
  job_name = "your-job-name"

  # Vault ID (required when getting specific job)
  replication_vault_id = "/subscriptions/xxx/resourceGroups/xxx/providers/Microsoft.DataReplication/replicationVaults/xxx"
}

# Outputs

# List all jobs
output "all_jobs" {
  description = "All replication jobs"
  value       = module.list_all_jobs.replication_jobs
}

output "jobs_count" {
  description = "Total number of jobs"
  value       = module.list_all_jobs.replication_jobs_count
}

# Specific job details
output "job_details" {
  description = "Details of the specific job"
  value       = module.get_specific_job.replication_job
}
