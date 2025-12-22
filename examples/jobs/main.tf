# Example: Get Replication Jobs
# This example demonstrates how to retrieve replication job status

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azapi = {
      source  = "azure/azapi"
      version = ">= 2.7.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.49.0"
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

  location = "eastus"
  # Required
  name                = "migration-jobs-list"
  resource_group_name = "your-resource-group"
  # Operation mode
  operation_mode = "jobs"
  # Project details (to find vault from solution)
  project_name = "your-migrate-project"
}

# Example 2: Get a specific job by name
module "get_specific_job" {
  source = "../../"

  location = "eastus"
  # Required
  name                = "migration-job-detail"
  resource_group_name = "your-resource-group"
  # Job to retrieve
  job_name = "your-job-name"
  # Operation mode
  operation_mode = "jobs"
  # Vault ID (required when getting specific job)
  replication_vault_id = "/subscriptions/xxx/resourceGroups/xxx/providers/Microsoft.DataReplication/replicationVaults/xxx"
}

# Outputs



