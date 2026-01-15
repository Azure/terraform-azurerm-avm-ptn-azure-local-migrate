# --------------------------------------------------------------------------------------------
# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License. See License.txt in the project root for license information.
# --------------------------------------------------------------------------------------------

variable "custom_location_id" {
  type        = string
  default     = "/subscriptions/0daa57b3-f823-4921-a09a-33c048e64022/resourceGroups/EDGECI-REGISTRATION-rr1n25r1606-i3dfqVNA/providers/Microsoft.ExtendedLocation/customLocations/n25r1606-cl-customLocation"
  description = "The full resource ID of the Azure Stack HCI custom location"
}

variable "disks_to_include" {
  type = list(object({
    disk_id                   = string
    disk_size_gb              = number
    disk_file_format          = optional(string, "VHDX")
    is_os_disk                = optional(bool, true)
    is_dynamic                = optional(bool, true)
    disk_physical_sector_size = optional(number, 512)
  }))
  default = [
    # {
    #   disk_id          = "6000C291-b808-b317-6162-d298b124743b"
    #   disk_size_gb     = 40
    #   disk_file_format = "VHDX"
    #   is_os_disk       = true
    #   is_dynamic       = true
    # }
  ]
  description = "Disks to include for replication (from machine properties)"
}

variable "hyperv_generation" {
  type        = string
  default     = "2"
  description = "Hyper-V generation (1 or 2)"
}

variable "instance_type" {
  type        = string
  default     = "VMwareToAzStackHCI"
  description = "The migration instance type (VMwareToAzStackHCI or HyperVToAzStackHCI)"
}

variable "is_dynamic_memory_enabled" {
  type        = bool
  default     = false
  description = "Whether dynamic memory is enabled for the target VM"
}

variable "location" {
  type        = string
  default     = null
  description = "Optional: The Azure region (custom location region). If not specified, uses the resource group's location."
}

variable "machine_id" {
  type        = string
  default     = "/subscriptions/f6f66a94-f184-45da-ac12-ffbfd8a6eb29/resourceGroups/saif-project-120126-rg/providers/Microsoft.OffAzure/VMwareSites/src3225site/machines/100-69-177-104-f0d9ffab-ffc9-4567-84a3-792f2f01fc57_5023a8b8-6ecc-b7ad-4e88-8db9f80f737c"
  description = "The full resource ID of the machine to replicate (OffAzure/VMwareSites path)"
}

variable "nics_to_include" {
  type = list(object({
    nic_id            = string
    target_network_id = string
    test_network_id   = optional(string)
    selection_type    = optional(string, "SelectedByUser")
  }))
  default = [
    # {
    #   nic_id            = "4000"
    #   target_network_id = "/subscriptions/0daa57b3-f823-4921-a09a-33c048e64022/resourceGroups/EDGECI-REGISTRATION-rr1n25r1606-i3dfqVNA/providers/Microsoft.AzureStackHCI/logicalnetworks/lnet-n25r1606-cl"
    #   test_network_id   = "/subscriptions/0daa57b3-f823-4921-a09a-33c048e64022/resourceGroups/EDGECI-REGISTRATION-rr1n25r1606-i3dfqVNA/providers/Microsoft.AzureStackHCI/logicalnetworks/lnet-n25r1606-cl"
    #   selection_type    = "SelectedByUser"
    # },
    # {
    #   nic_id            = "4001"
    #   target_network_id = "/subscriptions/0daa57b3-f823-4921-a09a-33c048e64022/resourceGroups/EDGECI-REGISTRATION-rr1n25r1606-i3dfqVNA/providers/Microsoft.AzureStackHCI/logicalnetworks/lnet-n25r1606-cl"
    #   test_network_id   = "/subscriptions/0daa57b3-f823-4921-a09a-33c048e64022/resourceGroups/EDGECI-REGISTRATION-rr1n25r1606-i3dfqVNA/providers/Microsoft.AzureStackHCI/logicalnetworks/lnet-n25r1606-cl"
    #   selection_type    = "SelectedByUser"
    # },
    # {
    #   nic_id            = "4002"
    #   target_network_id = "/subscriptions/0daa57b3-f823-4921-a09a-33c048e64022/resourceGroups/EDGECI-REGISTRATION-rr1n25r1606-i3dfqVNA/providers/Microsoft.AzureStackHCI/logicalnetworks/lnet-n25r1606-cl"
    #   test_network_id   = "/subscriptions/0daa57b3-f823-4921-a09a-33c048e64022/resourceGroups/EDGECI-REGISTRATION-rr1n25r1606-i3dfqVNA/providers/Microsoft.AzureStackHCI/logicalnetworks/lnet-n25r1606-cl"
    #   selection_type    = "SelectedByUser"
    # }
  ]
  description = "NICs to include for replication (from machine properties)"
}

variable "os_disk_id" {
  type        = string
  default     = "6000C291-b808-b317-6162-d298b124743b"
  description = "The OS disk ID of the source VM"
}

variable "policy_name" {
  type        = string
  default     = "saif-project-16712replicationvaultVMwareToAzStackHCIpolicy"
  description = "The name of the replication policy"
}

variable "project_name" {
  type        = string
  default     = "saif-project-120126"
  description = "The name of the Azure Migrate project"
}

variable "replication_extension_name" {
  type        = string
  default     = "srcd586replicationfabric-tgt7f56replicationfabric-MigReplicationExtn"
  description = "The name of the replication extension"
}

variable "replication_vault_id" {
  type        = string
  default     = "/subscriptions/f6f66a94-f184-45da-ac12-ffbfd8a6eb29/resourceGroups/saif-project-120126-rg/providers/Microsoft.DataReplication/replicationVaults/saif-project-16712replicationvault"
  description = "The full resource ID of the replication vault"
}

variable "resource_group_name" {
  type        = string
  default     = "saif-project-120126-rg"
  description = "The name of the resource group containing the Azure Migrate project"
}

variable "run_as_account_id" {
  type        = string
  default     = "/subscriptions/f6f66a94-f184-45da-ac12-ffbfd8a6eb29/resourceGroups/saif-project-120126-rg/providers/Microsoft.OffAzure/VMwareSites/src3225site/runasaccounts/58093f44-117a-561b-be13-d751e1b22ca9"
  description = "The full resource ID of the run as account (from vCenter)"
}

variable "source_appliance_name" {
  type        = string
  default     = "src"
  description = "The name prefix for the source appliance"
}

variable "source_fabric_agent_name" {
  type        = string
  default     = "srcd586dra"
  description = "The name of the source fabric DRA"
}

variable "source_vm_cpu_cores" {
  type        = number
  default     = 4
  description = "Number of CPU cores in the source VM"
}

variable "source_vm_ram_mb" {
  type        = number
  default     = 8192
  description = "Amount of RAM in MB in the source VM"
}

variable "subscription_id" {
  type        = string
  default     = "f6f66a94-f184-45da-ac12-ffbfd8a6eb29"
  description = "The Azure subscription ID where resources will be deployed"
}

variable "tags" {
  type = map(string)
  default = {
    Environment = "Production"
    Purpose     = "HCI Migration Infrastructure"
    Owner       = "IT Team"
  }
  description = "Tags to apply to all resources"
}

variable "target_appliance_name" {
  type        = string
  default     = "tgt"
  description = "The name prefix for the target appliance (from initialize variables)"
}

variable "target_fabric_agent_name" {
  type        = string
  default     = "tgt7f56dra"
  description = "The name of the target fabric DRA"
}

variable "target_hci_cluster_id" {
  type        = string
  default     = "/subscriptions/0daa57b3-f823-4921-a09a-33c048e64022/resourceGroups/EDGECI-REGISTRATION-rr1n25r1606-i3dfqVNA/providers/Microsoft.AzureStackHCI/clusters/n25r1606-cl"
  description = "The full resource ID of the target Azure Stack HCI cluster"
}

variable "target_resource_group_id" {
  type        = string
  default     = "/subscriptions/0daa57b3-f823-4921-a09a-33c048e64022/resourceGroups/saif-project-120126-rg"
  description = "The full resource ID of the target resource group"
}

variable "target_storage_path_id" {
  type        = string
  default     = "/subscriptions/0daa57b3-f823-4921-a09a-33c048e64022/resourceGroups/EDGECI-REGISTRATION-rr1n25r1606-i3dfqVNA/providers/Microsoft.AzureStackHCI/storageContainers/UserStorage1-bd705ded518141ff99bbefb30642e19f"
  description = "The full resource ID of the target storage path"
}

variable "target_virtual_switch_id" {
  type        = string
  default     = "/subscriptions/0daa57b3-f823-4921-a09a-33c048e64022/resourceGroups/EDGECI-REGISTRATION-rr1n25r1606-i3dfqVNA/providers/Microsoft.AzureStackHCI/logicalnetworks/lnet-n25r1606-cl"
  description = "The full resource ID of the target virtual switch/network"
}

variable "target_vm_cpu_cores" {
  type        = number
  default     = 4
  description = "Number of CPU cores for the target VM"
}

variable "target_vm_name" {
  type        = string
  default     = "MigratedVmTerraform"
  description = "The name for the migrated VM on Azure Stack HCI"
}

variable "target_vm_ram_mb" {
  type        = number
  default     = 8192
  description = "Amount of RAM in MB for the target VM"
}
