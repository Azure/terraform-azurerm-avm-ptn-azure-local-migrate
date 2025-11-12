terraform {
  required_version = ">= 1.5.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.52.0"
    }
    azapi = {
      source  = "Azure/azapi"
      version = ">= 2.7.0"
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

  # Basic configuration
  name                = "migration-remove-example"
  location            = "eastus"
  resource_group_name = "rg-migration-example"

  # Operation mode
  operation_mode = "remove"

  # Protected item to remove
  # You can get this ID from the output of the replicate operation
  # or by querying existing protected items
  target_object_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-migration-example/providers/Microsoft.DataReplication/replicationVaults/vault-migration/protectedItems/vm-web-server-01"

  # Normal removal (default)
  force_remove = false
}

output "removal_status" {
  description = "Status of the removal operation"
  value       = module.remove_replication.removal_status
}

output "protected_item_info" {
  description = "Information about the protected item before removal"
  value       = module.remove_replication.protected_item_details
}

output "operation_headers" {
  description = "Response headers with job tracking information"
  value       = module.remove_replication.removal_operation_headers
}

# ========================================
# Example 2: Force Replication Removal
# ========================================
# Force removes replication when normal removal fails or is not possible.
# Use with caution as this may leave resources in an inconsistent state.

module "force_remove_replication" {
  source = "../.."

  # Basic configuration
  name                = "migration-force-remove-example"
  location            = "eastus"
  resource_group_name = "rg-migration-example"

  # Operation mode
  operation_mode = "remove"

  # Protected item to remove
  target_object_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-migration-example/providers/Microsoft.DataReplication/replicationVaults/vault-migration/protectedItems/vm-database-01"

  # Force removal - use when normal removal is not possible
  force_remove = true
}

output "force_removal_status" {
  description = "Status of the force removal operation"
  value       = module.force_remove_replication.removal_status
}

# ========================================
# Example 3: Remove with Job Tracking
# ========================================
# Remove replication and track the removal job status

module "remove_with_tracking" {
  source = "../.."

  # Basic configuration
  name                = "migration-remove-tracking"
  location            = "eastus"
  resource_group_name = "rg-migration-example"

  # Operation mode
  operation_mode = "remove"

  # Protected item to remove
  target_object_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-migration-example/providers/Microsoft.DataReplication/replicationVaults/vault-migration/protectedItems/vm-app-server-02"

  force_remove = false
}

# Extract job information from the response headers
locals {
  # The Azure-AsyncOperation or Location header contains the job tracking URL
  operation_location = try(module.remove_with_tracking.removal_operation_headers.Azure-AsyncOperation,
                          try(module.remove_with_tracking.removal_operation_headers.Location, null))

  # Parse the job name from the operation location
  # Format: .../jobs/{jobName}?...
  job_name = local.operation_location != null ? (
    length(regexall("/jobs/([^?/]+)", local.operation_location)) > 0 ?
    regexall("/jobs/([^?/]+)", local.operation_location)[0][0] : null
  ) : null
}

# Use the jobs operation mode to track the removal job
module "track_removal_job" {
  source = "../.."
  count  = local.job_name != null ? 1 : 0

  # Basic configuration
  name                = "migration-track-removal"
  location            = "eastus"
  resource_group_name = "rg-migration-example"

  # Operation mode for job tracking
  operation_mode = "jobs"

  # Project name to find the vault
  project_name = "migration-project"

  # Specific job to track
  job_name = local.job_name

  # Depends on the removal operation completing
  depends_on = [module.remove_with_tracking]
}

output "removal_job_details" {
  description = "Details of the removal job"
  value       = length(module.track_removal_job) > 0 ? module.track_removal_job[0].replication_job : null
}

output "removal_job_name" {
  description = "Name of the removal job for tracking"
  value       = local.job_name
}
