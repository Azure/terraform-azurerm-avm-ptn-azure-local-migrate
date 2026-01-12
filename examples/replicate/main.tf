# --------------------------------------------------------------------------------------------
# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License. See License.txt in the project root for license information.
# --------------------------------------------------------------------------------------------
#
# Example: Create VM Replication
# This example demonstrates how to create replication for a VM to Azure Stack HCI
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

# Create replication for a specific VM
module "replicate_vm" {
  source = "../../"

  location                  = var.location
  name                      = "vm-replication"
  resource_group_name       = var.resource_group_name
  custom_location_id        = var.custom_location_id
  hyperv_generation         = var.hyperv_generation
  instance_type             = var.instance_type
  is_dynamic_memory_enabled = var.is_dynamic_memory_enabled
  machine_id                = var.machine_id
  operation_mode            = "replicate"
  os_disk_id                = var.os_disk_id
  policy_name               = var.policy_name
  project_name              = var.project_name
  replication_extension_name = var.replication_extension_name
  replication_vault_id      = var.replication_vault_id
  run_as_account_id         = var.run_as_account_id
  source_appliance_name     = var.source_appliance_name
  source_fabric_agent_name  = var.source_fabric_agent_name
  source_vm_cpu_cores       = var.source_vm_cpu_cores
  source_vm_ram_mb          = var.source_vm_ram_mb
  tags                      = var.tags
  target_appliance_name     = var.target_appliance_name
  target_fabric_agent_name  = var.target_fabric_agent_name
  target_hci_cluster_id     = var.target_hci_cluster_id
  target_resource_group_id  = var.target_resource_group_id
  target_storage_path_id    = var.target_storage_path_id
  target_virtual_switch_id  = var.target_virtual_switch_id
  target_vm_cpu_cores       = var.target_vm_cpu_cores
  target_vm_name            = var.target_vm_name
  target_vm_ram_mb          = var.target_vm_ram_mb
}



