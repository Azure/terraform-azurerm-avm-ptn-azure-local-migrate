# Example: Create VM Replication
# This example demonstrates how to create replication for a VM to Azure Stack HCI
#
# There are two modes for configuring disks and NICs:
#
# 1. POWER USER MODE (recommended for full control):
#    - Provide disks_to_include: list of all disks with their IDs, sizes, and OS disk flag
#    - Provide nics_to_include: list of NICs with network mappings
#
# 2. DEFAULT USER MODE (simpler, single disk/NIC):
#    - Provide os_disk_id, os_disk_size_gb for the OS disk
#    - Provide nic_id, target_virtual_switch_id for the NIC
#
# This example uses POWER USER MODE with explicit disk and NIC configurations.
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

# Create replication for a specific VM (POWER USER MODE)
module "replicate_vm" {
  source = "../../"

  location                   = var.location
  name                       = "vm-replication"
  parent_id                  = var.parent_id
  custom_location_id         = var.custom_location_id
  disks_to_include           = var.disks_to_include
  hyperv_generation          = var.hyperv_generation
  instance_type              = var.instance_type
  is_dynamic_memory_enabled  = var.is_dynamic_memory_enabled
  machine_id                 = var.machine_id
  nic_id                     = var.nic_id # For default user mode
  nics_to_include            = var.nics_to_include
  operation_mode             = "replicate"
  os_disk_id                 = var.os_disk_id
  os_disk_size_gb            = var.os_disk_size_gb # For default user mode
  policy_name                = var.policy_name
  project_name               = var.project_name
  replication_extension_name = var.replication_extension_name
  replication_vault_id       = var.replication_vault_id
  run_as_account_id          = var.run_as_account_id
  source_appliance_name      = var.source_appliance_name
  source_fabric_agent_name   = var.source_fabric_agent_name
  source_vm_cpu_cores        = var.source_vm_cpu_cores
  source_vm_ram_mb           = var.source_vm_ram_mb
  tags                       = var.tags
  target_appliance_name      = var.target_appliance_name
  target_fabric_agent_name   = var.target_fabric_agent_name
  target_hci_cluster_id      = var.target_hci_cluster_id
  target_resource_group_id   = var.target_resource_group_id
  target_storage_path_id     = var.target_storage_path_id
  target_virtual_switch_id   = var.target_virtual_switch_id
  target_vm_cpu_cores        = var.target_vm_cpu_cores
  target_vm_name             = var.target_vm_name
  target_vm_ram_mb           = var.target_vm_ram_mb
}



