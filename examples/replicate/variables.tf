# --------------------------------------------------------------------------------------------
# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License. See License.txt in the project root for license information.
# --------------------------------------------------------------------------------------------

variable "subscription_id" {
  type        = string
  description = "The Azure subscription ID where resources will be deployed"
  default     = "f6f66a94-f184-45da-ac12-ffbfd8a6eb29"
}

variable "resource_group_name" {
  type        = string
  description = "The name of the resource group containing the Azure Migrate project"
  default     = "saif-project-120126-rg"
}

variable "project_name" {
  type        = string
  description = "The name of the Azure Migrate project"
  default     = "saif-project-120126"
}

variable "location" {
  type        = string
  description = "The Azure region where resources will be deployed (custom location region)"
  default     = "australiaeast"
}

variable "instance_type" {
  type        = string
  description = "The migration instance type (VMwareToAzStackHCI or HyperVToAzStackHCI)"
  default     = "VMwareToAzStackHCI"
}

variable "machine_id" {
  type        = string
  description = "The full resource ID of the machine to replicate (OffAzure/VMwareSites path)"
  default     = "/subscriptions/f6f66a94-f184-45da-ac12-ffbfd8a6eb29/resourceGroups/saif-project-120126-rg/providers/Microsoft.OffAzure/VMwareSites/src3225site/machines/100-69-177-104-f0d9ffab-ffc9-4567-84a3-792f2f01fc57_5023a8b8-6ecc-b7ad-4e88-8db9f80f737c"
}

variable "os_disk_id" {
  type        = string
  description = "The OS disk ID of the source VM"
  default     = "6000C291-b808-b317-6162-d298b124743b"
}

variable "replication_vault_id" {
  type        = string
  description = "The full resource ID of the replication vault"
  default     = "/subscriptions/f6f66a94-f184-45da-ac12-ffbfd8a6eb29/resourceGroups/saif-project-120126-rg/providers/Microsoft.DataReplication/replicationVaults/saif-project-16712replicationvault"
}

variable "replication_extension_name" {
  type        = string
  description = "The name of the replication extension"
  default     = "srcd586replicationfabric-tgt7f56replicationfabric-MigReplicationExtn"
}

variable "policy_name" {
  type        = string
  description = "The name of the replication policy"
  default     = "saif-project-16712replicationvaultVMwareToAzStackHCIpolicy"
}

variable "run_as_account_id" {
  type        = string
  description = "The full resource ID of the run as account (from vCenter)"
  default     = "/subscriptions/f6f66a94-f184-45da-ac12-ffbfd8a6eb29/resourceGroups/saif-project-120126-rg/providers/Microsoft.OffAzure/VMwareSites/src3225site/runasaccounts/58093f44-117a-561b-be13-d751e1b22ca9"
}

variable "custom_location_id" {
  type        = string
  description = "The full resource ID of the Azure Stack HCI custom location"
  default     = "/subscriptions/0daa57b3-f823-4921-a09a-33c048e64022/resourceGroups/EDGECI-REGISTRATION-rr1n25r1606-i3dfqVNA/providers/Microsoft.ExtendedLocation/customLocations/n25r1606-cl-customLocation"
}

variable "target_hci_cluster_id" {
  type        = string
  description = "The full resource ID of the target Azure Stack HCI cluster"
  default     = "/subscriptions/0daa57b3-f823-4921-a09a-33c048e64022/resourceGroups/EDGECI-REGISTRATION-rr1n25r1606-i3dfqVNA/providers/Microsoft.AzureStackHCI/clusters/n25r1606-cl"
}

variable "target_resource_group_id" {
  type        = string
  description = "The full resource ID of the target resource group"
  default     = "/subscriptions/0daa57b3-f823-4921-a09a-33c048e64022/resourceGroups/saif-project-120126-rg"
}

variable "target_storage_path_id" {
  type        = string
  description = "The full resource ID of the target storage path"
  default     = "/subscriptions/0daa57b3-f823-4921-a09a-33c048e64022/resourceGroups/EDGECI-REGISTRATION-rr1n25r1606-i3dfqVNA/providers/Microsoft.AzureStackHCI/storageContainers/UserStorage1-bd705ded518141ff99bbefb30642e19f"
}

variable "target_virtual_switch_id" {
  type        = string
  description = "The full resource ID of the target virtual switch/network"
  default     = "/subscriptions/0daa57b3-f823-4921-a09a-33c048e64022/resourceGroups/EDGECI-REGISTRATION-rr1n25r1606-i3dfqVNA/providers/Microsoft.AzureStackHCI/logicalnetworks/lnet-n25r1606-cl"
}

variable "source_appliance_name" {
  type        = string
  description = "The name prefix for the source appliance"
  default     = "src"
}

variable "target_appliance_name" {
  type        = string
  description = "The name prefix for the target appliance (from initialize variables)"
  default     = "tgt"
}

variable "source_fabric_agent_name" {
  type        = string
  description = "The name of the source fabric DRA"
  default     = "srcd586dra"
}

variable "target_fabric_agent_name" {
  type        = string
  description = "The name of the target fabric DRA"
  default     = "tgt7f56dra"
}

variable "source_vm_cpu_cores" {
  type        = number
  description = "Number of CPU cores in the source VM"
  default     = 4
}

variable "source_vm_ram_mb" {
  type        = number
  description = "Amount of RAM in MB in the source VM"
  default     = 8192
}

variable "target_vm_name" {
  type        = string
  description = "The name for the migrated VM on Azure Stack HCI"
  default     = "MigratedVmTerraform"
}

variable "target_vm_cpu_cores" {
  type        = number
  description = "Number of CPU cores for the target VM"
  default     = 4
}

variable "target_vm_ram_mb" {
  type        = number
  description = "Amount of RAM in MB for the target VM"
  default     = 8192
}

variable "hyperv_generation" {
  type        = string
  description = "Hyper-V generation (1 or 2)"
  default     = "2"
}

variable "is_dynamic_memory_enabled" {
  type        = bool
  description = "Whether dynamic memory is enabled for the target VM"
  default     = false
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to all resources"
  default = {
    Environment = "Production"
    Purpose     = "HCI Migration Infrastructure"
    Owner       = "IT Team"
  }
}

variable "nics_to_include" {
  type = list(object({
    nic_id            = string
    target_network_id = string
    test_network_id   = optional(string)
    selection_type    = optional(string, "SelectedByUser")
  }))
  description = "NICs to include for replication (from machine properties)"
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
  description = "Disks to include for replication (from machine properties)"
  default = [
    # {
    #   disk_id          = "6000C291-b808-b317-6162-d298b124743b"
    #   disk_size_gb     = 40
    #   disk_file_format = "VHDX"
    #   is_os_disk       = true
    #   is_dynamic       = true
    # }
  ]
}
