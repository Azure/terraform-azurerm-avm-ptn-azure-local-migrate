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
  subscription_id = "f6f66a94-f184-45da-ac12-ffbfd8a6eb29"
}

# Initialize replication infrastructure for VMware to Azure Stack HCI migration
module "initialize_replication" {
  source = "../../"

  location = "eastus"
  name     = "hci-migration-init"
  # Resource configuration
  resource_group_name                = "saifaldinali-vmw-ga-bb-rg"
  app_consistent_frequency_minutes   = 240 # 4 hours
  crash_consistent_frequency_minutes = 60  # 1 hour
  # Instance type (VMware to HCI or HyperV to HCI)
  instance_type = "VMwareToAzStackHCI"
  # Operation mode
  operation_mode = "initialize"
  # Migration project
  project_name = "saifaldinali-vmw-ga-bb"
  # Replication policy settings
  recovery_point_history_minutes = 4320 # 72 hours
  # Appliance names
  source_appliance_name = "src"
  # Fabric IDs (obtained from Azure Migrate)
  source_fabric_id = "/subscriptions/f6f66a94-f184-45da-ac12-ffbfd8a6eb29/resourceGroups/saifaldinali-vmw-ga-bb-rg/providers/Microsoft.DataReplication/replicationFabrics/src23b3replicationfabric"
  tags = {
    Environment = "Production"
    Purpose     = "HCI Migration Infrastructure"
    Owner       = "IT Team"
  }
  target_appliance_name = "tgt2"
  target_fabric_id      = "/subscriptions/f6f66a94-f184-45da-ac12-ffbfd8a6eb29/resourceGroups/saifaldinali-vmw-ga-bb-rg/providers/Microsoft.DataReplication/replicationFabrics/tgt28eb7replicationfabric"
}





