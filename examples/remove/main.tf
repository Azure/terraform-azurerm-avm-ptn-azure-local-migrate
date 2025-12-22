terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azapi = {
      source  = "Azure/azapi"
      version = ">= 2.7.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.52.0"
    }
  }
}

provider "azurerm" {
  features {}
}

provider "azapi" {}

# ========================================
# Example 1: Normal Replication Removal
# ========================================
# Stops replication for a protected server using standard removal.
# This is the recommended approach for normal scenarios.

module "remove_replication" {
  source = "../.."

  location = "eastus"
  # Basic configuration
  name                = "migration-remove-example"
  resource_group_name = "rg-migration-example"
  # Normal removal (default)
  force_remove = false
  # Operation mode
  operation_mode = "remove"
  # Protected item to remove
  # You can get this ID from the output of the replicate operation
  # or by querying existing protected items
  target_object_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-migration-example/providers/Microsoft.DataReplication/replicationVaults/vault-migration/protectedItems/vm-web-server-01"
}




# ========================================
# Example 2: Force Replication Removal
# ========================================
# Force removes replication when normal removal fails or is not possible.
# Use with caution as this may leave resources in an inconsistent state.

module "force_remove_replication" {
  source = "../.."

  location = "eastus"
  # Basic configuration
  name                = "migration-force-remove-example"
  resource_group_name = "rg-migration-example"
  # Force removal - use when normal removal is not possible
  force_remove = true
  # Operation mode
  operation_mode = "remove"
  # Protected item to remove
  target_object_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-migration-example/providers/Microsoft.DataReplication/replicationVaults/vault-migration/protectedItems/vm-database-01"
}


# ========================================
# Example 3: Remove with Job Tracking
# ========================================
# Remove replication and track the removal job status

module "remove_with_tracking" {
  source = "../.."

  location = "eastus"
  # Basic configuration
  name                = "migration-remove-tracking"
  resource_group_name = "rg-migration-example"
  force_remove        = false
  # Operation mode
  operation_mode = "remove"
  # Protected item to remove
  target_object_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-migration-example/providers/Microsoft.DataReplication/replicationVaults/vault-migration/protectedItems/vm-app-server-02"
}

# Extract job information from the response headers
locals {
  # Parse the job name from the operation location
  # Format: .../jobs/{jobName}?...
  job_name = local.operation_location != null ? (
    length(regexall("/jobs/([^?/]+)", local.operation_location)) > 0 ?
    regexall("/jobs/([^?/]+)", local.operation_location)[0][0] : null
  ) : null
  # The Azure-AsyncOperation or Location header contains the job tracking URL
  operation_location = try(module.remove_with_tracking.removal_operation_headers.Azure-AsyncOperation,
  try(module.remove_with_tracking.removal_operation_headers.Location, null))
}

# Use the jobs operation mode to track the removal job
module "track_removal_job" {
  source = "../.."
  count  = local.job_name != null ? 1 : 0

  location = "eastus"
  # Basic configuration
  name                = "migration-track-removal"
  resource_group_name = "rg-migration-example"
  # Specific job to track
  job_name = local.job_name
  # Operation mode for job tracking
  operation_mode = "jobs"
  # Project name to find the vault
  project_name = "migration-project"

  # Depends on the removal operation completing
  depends_on = [module.remove_with_tracking]
}


