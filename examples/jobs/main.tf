# Example: Get Replication Jobs
# This example demonstrates how to retrieve replication job status
#

terraform {
  required_version = ">= 1.9"

  required_providers {
    azapi = {
      source  = "Azure/azapi"
      version = "~> 2.4"
    }
  }
}

provider "azapi" {}

# Get replication jobs
module "replication_jobs" {
  source  = "Azure/avm-ptn-azure-local-migrate/azurerm"
  version = "0.1.2"

  name           = "replication-jobs"
  parent_id      = var.parent_id
  operation_mode = "jobs"
  project_name   = var.project_name
  # Optional: pass an explicit vault ID. When omitted, the vault is
  # auto-resolved from the migrate project's Server Migration solution.
  replication_vault_id = var.replication_vault_id
  tags                 = var.tags
}

