# Example: Initialize Replication Infrastructure
# This example demonstrates how to initialize the replication infrastructure
# for Azure Stack HCI migration
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

# Initialize replication infrastructure for VMware to Azure Stack HCI migration
# NOTE: Fabric IDs are automatically discovered from appliance names
# You only need to provide source_appliance_name and target_appliance_name
module "initialize_replication" {
  source = "../../"

  # Location for resources
  location  = var.location
  name      = "hci-migration-init"
  parent_id = var.parent_id
  # Replication policy settings
  app_consistent_frequency_minutes   = var.app_consistent_frequency_minutes
  crash_consistent_frequency_minutes = var.crash_consistent_frequency_minutes
  # Instance type (VMware to HCI or HyperV to HCI)
  instance_type = var.instance_type
  # Operation mode
  operation_mode = "initialize"
  # Migration project
  project_name = var.project_name
  # Recovery point retention
  recovery_point_history_minutes = var.recovery_point_history_minutes
  # Appliance names - fabrics are auto-discovered from these
  source_appliance_name = var.source_appliance_name
  # Optional: explicit fabric IDs (override auto-discovery if needed)
  source_fabric_id      = var.source_fabric_id
  tags                  = var.tags
  target_appliance_name = var.target_appliance_name
  target_fabric_id      = var.target_fabric_id
}





