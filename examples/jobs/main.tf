# Example: Get Replication Jobs
# This example demonstrates how to retrieve replication job status
#

terraform {
  required_version = ">= 1.9"

  required_providers {
    azapi = {
      source  = "azure/azapi"
      version = "~> 2.4"
    }
  }
}

provider "azapi" {}

# Get replication jobs
module "replication_jobs" {
  source = "../../"

  location       = var.location
  name           = "replication-jobs"
  parent_id      = var.parent_id
  instance_type  = var.instance_type
  operation_mode = "jobs"
  project_name   = var.project_name
  # Use explicit vault ID
  replication_vault_id = var.replication_vault_id
  tags                 = var.tags
}

