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
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.71, < 5.0"
    }
    azapi = {
      source  = "azure/azapi"
      version = ">= 1.9, < 3.0"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id = "f6f66a94-f184-45da-ac12-ffbfd8a6eb29"
}

# Create replication for a specific VM
module "replicate_vm" {
  source = "../../"

  # Operation mode
  operation_mode = "replicate"

  # Azure Migrate Project
  project_name = "saifaldinali-vmw-ga-bb"

  # Resource configuration
  resource_group_name = "saifaldinali-vmw-ga-bb-rg"
  location            = "eastus"
  name                = "vm-replication"

  # Machine to replicate - GPOTest-PC2 (using GUID as machine name)
  machine_id = "/subscriptions/f6f66a94-f184-45da-ac12-ffbfd8a6eb29/resourceGroups/saifaldinali-vmw-ga-bb-rg/providers/Microsoft.Migrate/migrateprojects/saifaldinali-vmw-ga-bb/machines/502337ea-92b2-0431-f9bf-a191c0f58a34"

  # Target configuration
  target_vm_name           = "MigratedVmAzCLI"
  target_storage_path_id   = "/subscriptions/304d8fdf-1c02-4907-9c3a-ddbd677199cd/resourceGroups/EDGECI-REGISTRATION-rr1n26r1508-PWxduHTU/providers/Microsoft.AzureStackHCI/storageContainers/UserStorage1-21ad348ce97c47d286143fa0a53dcd86"
  target_resource_group_id = "/subscriptions/304d8fdf-1c02-4907-9c3a-ddbd677199cd/resourceGroups/saifaldinali-vmx-ga-bb-rg"

  # VM sizing
  target_vm_cpu_cores = 4
  target_vm_ram_mb    = 8192
  is_dynamic_memory_enabled = false
  hyperv_generation   = "2"

  # Replication configuration
  replication_vault_id      = "/subscriptions/f6f66a94-f184-45da-ac12-ffbfd8a6eb29/resourceGroups/saifaldinali-vmw-ga-bb-rg/providers/Microsoft.DataReplication/replicationVaults/saifaldinalivmwgabbreplicationvault"
  policy_name               = "saifaldinalivmwgabbreplicationvaultVMwareToAzStackHCIpolicy"
  replication_extension_name = "src23b3replicationfabric-tgt28eb7replicationfabric-MigReplicationExtn"

  # Fabric and DRA configuration
  source_fabric_agent_name = "vmware-source-dra"
  target_fabric_agent_name = "hci-target-dra"
  run_as_account_id        = "/subscriptions/f6f66a94-f184-45da-ac12-ffbfd8a6eb29/resourceGroups/saifaldinali-vmw-ga-bb-rg/providers/Microsoft.OffAzure/VMwareSites/vmware-site/runAsAccounts/vcenter-account"

  # Custom location and HCI cluster
  custom_location_id  = "/subscriptions/304d8fdf-1c02-4907-9c3a-ddbd677199cd/resourceGroups/EDGECI-REGISTRATION-rr1n26r1508-PWxduHTU/providers/Microsoft.ExtendedLocation/customLocations/hci-custom-location"
  target_hci_cluster_id = "/subscriptions/304d8fdf-1c02-4907-9c3a-ddbd677199cd/resourceGroups/EDGECI-REGISTRATION-rr1n26r1508-PWxduHTU/providers/Microsoft.AzureStackHCI/clusters/hci-cluster-01"

  # OS Disk (from GPOTest-PC2 machine)
  os_disk_id = "6000C29f-7e33-32c7-73bc-5d4136822573"

  # Virtual Switch (Network)
  target_virtual_switch_id = "/subscriptions/304d8fdf-1c02-4907-9c3a-ddbd677199cd/resourceGroups/EDGECI-REGISTRATION-rr1n26r1508-PWxduHTU/providers/Microsoft.AzureStackHCI/logicalnetworks/n26r1508-lnet"

  # Source VM metadata
  source_vm_cpu_cores = 2
  source_vm_ram_mb    = 4096
  instance_type       = "VMwareToAzStackHCI"

  # Appliance names
  source_appliance_name = "src"
  target_appliance_name = "tgt2"

  tags = {
    Environment = "Production"
    Purpose     = "VM Migration"
    Project     = "saifaldinali-vmw-ga-bb"
  }
}

# Outputs
output "protected_item_id" {
  value       = module.replicate_vm.protected_item_id
  description = "ID of the protected item (replicated VM)"
}

output "replication_state" {
  value       = module.replicate_vm.replication_state
  description = "Current replication state"
}

output "target_vm_name" {
  value       = module.replicate_vm.target_vm_name_output
  description = "Name of the target VM"
}
