variable "parent_id" {
  type        = string
  description = "The resource ID of the resource group containing the Azure Migrate project. Format: /subscriptions/{subscription-id}/resourceGroups/{resource-group-name}"
}

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
    {
      disk_id          = "6000C29f-59f4-37d9-acdd-8f90d99d07e0"
      disk_size_gb     = 40
      disk_file_format = "VHDX"
      is_os_disk       = true
      is_dynamic       = true
    },
    {
      disk_id          = "6000C295-9144-b82d-a8fc-9c0e27fe3b41"
      disk_size_gb     = 10
      disk_file_format = "VHDX"
      is_os_disk       = false
      is_dynamic       = true
    },
    {
      disk_id          = "6000C29b-4a7e-0e87-e286-74b13f11055b"
      disk_size_gb     = 10
      disk_file_format = "VHDX"
      is_os_disk       = false
      is_dynamic       = true
    }
  ]
  description = "Disks to include for replication (from machine properties)"
}

variable "hyperv_generation" {
  type        = string
  default     = "1"
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
  default     = "eastus"
  description = "The Azure region (custom location region). Must be a region where Microsoft.AzureStackHCI resources are available."
}

variable "machine_id" {
  type        = string
  default     = "/subscriptions/f6f66a94-f184-45da-ac12-ffbfd8a6eb29/resourceGroups/saif-project-012726-rg/providers/Microsoft.OffAzure/VMwareSites/src7681site/machines/100-69-177-104-36bf83bc-c03b-4c08-853c-187db9aa17e8_50232086-5a0d-7205-68e2-bc2391e7a0a7"
  description = "The full resource ID of the machine to replicate (OffAzure/VMwareSites path)"
}

# Default user mode variables (alternative to nics_to_include)
variable "nic_id" {
  type        = string
  default     = null # Set to a NIC ID like "4000" to use DEFAULT USER MODE
  description = "NIC ID for DEFAULT USER MODE. Used when nics_to_include is not provided but target_virtual_switch_id is specified."
}

variable "nics_to_include" {
  type = list(object({
    nic_id            = string
    target_network_id = string
    test_network_id   = optional(string)
    selection_type    = optional(string, "SelectedByUser")
  }))
  default = [
    {
      nic_id            = "4000"
      target_network_id = "/subscriptions/0daa57b3-f823-4921-a09a-33c048e64022/resourceGroups/EDGECI-REGISTRATION-rr1n25r1606-i3dfqVNA/providers/Microsoft.AzureStackHCI/logicalnetworks/lnet-n25r1606-cl"
      test_network_id   = "/subscriptions/0daa57b3-f823-4921-a09a-33c048e64022/resourceGroups/EDGECI-REGISTRATION-rr1n25r1606-i3dfqVNA/providers/Microsoft.AzureStackHCI/logicalnetworks/lnet-n25r1606-cl"
      selection_type    = "SelectedByUser"
    }
  ]
  description = "NICs to include for replication (from machine properties). Use this for POWER USER MODE."
}

variable "os_disk_id" {
  type        = string
  default     = "6000C29f-59f4-37d9-acdd-8f90d99d07e0"
  description = "The OS disk ID of the source VM. Used for DEFAULT USER MODE when disks_to_include is not provided."
}

variable "os_disk_size_gb" {
  type        = number
  default     = 40
  description = "The OS disk size in GB for DEFAULT USER MODE. Used when disks_to_include is not provided."
}

variable "policy_name" {
  type        = string
  default     = "saif-project-01424replicationvaultVMwareToAzStackHCIpolicy"
  description = "The name of the replication policy"
}

variable "project_name" {
  type        = string
  default     = "saif-project-012726"
  description = "The name of the Azure Migrate project"
}

variable "replication_extension_name" {
  type        = string
  default     = "srcc048replicationfabric-tgt7945replicationfabric-MigReplicationExtn"
  description = "The name of the replication extension"
}

variable "replication_vault_id" {
  type        = string
  default     = "/subscriptions/f6f66a94-f184-45da-ac12-ffbfd8a6eb29/resourceGroups/saif-project-012726-rg/providers/Microsoft.DataReplication/replicationVaults/saif-project-01424replicationvault"
  description = "The full resource ID of the replication vault"
}

variable "run_as_account_id" {
  type        = string
  default     = "/subscriptions/f6f66a94-f184-45da-ac12-ffbfd8a6eb29/resourceGroups/saif-project-012726-rg/providers/Microsoft.OffAzure/VMwareSites/src7681site/runasaccounts/58093f44-117a-561b-be13-d751e1b22ca9"
  description = "The full resource ID of the run as account (from vCenter)"
}

variable "source_appliance_name" {
  type        = string
  default     = "src"
  description = "The name prefix for the source appliance"
}

variable "source_fabric_agent_name" {
  type        = string
  default     = "srcc048dra"
  description = "The name of the source fabric DRA"
}

variable "source_vm_cpu_cores" {
  type        = number
  default     = 2
  description = "Number of CPU cores in the source VM"
}

variable "source_vm_ram_mb" {
  type        = number
  default     = 4096
  description = "Amount of RAM in MB in the source VM"
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
  default     = "tgt7945dra"
  description = "The name of the target fabric DRA"
}

variable "target_hci_cluster_id" {
  type        = string
  default     = "/subscriptions/0daa57b3-f823-4921-a09a-33c048e64022/resourceGroups/EDGECI-REGISTRATION-rr1n25r1606-i3dfqVNA/providers/Microsoft.AzureStackHCI/clusters/n25r1606-cl"
  description = "The full resource ID of the target Azure Stack HCI cluster"
}

variable "target_resource_group_id" {
  type        = string
  default     = "/subscriptions/0daa57b3-f823-4921-a09a-33c048e64022/resourceGroups/saif-project-012726-rg"
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
  default     = 2
  description = "Number of CPU cores for the target VM"
}

variable "target_vm_name" {
  type        = string
  default     = "test-vm9-Migrated"
  description = "The name for the migrated VM on Azure Stack HCI"
}

variable "target_vm_ram_mb" {
  type        = number
  default     = 4096
  description = "Amount of RAM in MB for the target VM"
}
