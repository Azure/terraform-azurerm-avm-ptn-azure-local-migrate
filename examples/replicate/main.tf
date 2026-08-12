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

module "replicate_vm" {
  source  = "Azure/avm-ptn-azure-local-migrate/azurerm"
  version = "0.1.3"

  name           = "vm-replication"
  operation_mode = "replicate"
  parent_id      = var.parent_id
  project_name   = var.project_name

  # PowerShell-equivalent required parameters
  # (New-AzMigrateLocalServerReplication -ByIdDefaultUser)
  machine_id               = var.machine_id
  os_disk_id               = var.os_disk_id
  source_appliance_name    = var.source_appliance_name
  target_appliance_name    = var.target_appliance_name
  target_resource_group_id = var.target_resource_group_id
  target_storage_path_id   = var.target_storage_path_id
  target_virtual_switch_id = var.target_virtual_switch_id
  target_vm_name           = var.target_vm_name

  # Azure Local placement
  custom_location_id    = var.custom_location_id
  target_hci_cluster_id = var.target_hci_cluster_id
}
