# --------------------------------------------------------------------------------------------
# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License. See License.txt in the project root for license information.
# --------------------------------------------------------------------------------------------
#
# Example: Initialize Replication Infrastructure
# This example demonstrates how to initialize the replication infrastructure
# for Azure Stack HCI migration
#

terraform {
  required_version = ">= 1.5"

  required_providers {
    azapi = {
      source  = "azure/azapi"
      version = ">= 1.9, < 3.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.71, < 5.0"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}

# Initialize replication infrastructure for VMware to Azure Stack HCI migration
module "initialize_replication" {
  source = "../../"

  location = var.location
  name     = "hci-migration-init"
  # Resource configuration
  resource_group_name                = var.resource_group_name
  app_consistent_frequency_minutes   = var.app_consistent_frequency_minutes
  crash_consistent_frequency_minutes = var.crash_consistent_frequency_minutes
  # Instance type (VMware to HCI or HyperV to HCI)
  instance_type = var.instance_type
  # Operation mode
  operation_mode = "initialize"
  # Migration project
  project_name = var.project_name
  # Replication policy settings
  recovery_point_history_minutes = var.recovery_point_history_minutes
  # Appliance names
  source_appliance_name = var.source_appliance_name
  # Fabric IDs (obtained from Azure Migrate)
  source_fabric_id      = var.source_fabric_id
  tags                  = var.tags
  target_appliance_name = var.target_appliance_name
  target_fabric_id      = var.target_fabric_id
}





