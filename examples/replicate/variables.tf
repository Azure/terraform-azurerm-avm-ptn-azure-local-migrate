variable "parent_id" {
  type        = string
  default     = "/subscriptions/265ca7e5-909a-455d-9459-7c7041c1c37d/resourceGroups/saif-project-021826-rg"
  description = "The resource ID of the resource group containing the Azure Migrate project. Format: /subscriptions/{subscription-id}/resourceGroups/{resource-group-name}"
}

variable "custom_location_id" {
  type        = string
  default     = "/subscriptions/d41eb627-825d-4419-a14d-c6ad485f4110/resourceGroups/EDGECI-REGISTRATION-s46r1405-t8g6NRVO/providers/Microsoft.ExtendedLocation/customLocations/s46r1405-cl-customLocation"
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
      disk_id          = "6000C29c-262c-2f47-4313-0869276a9574"
      disk_size_gb     = 100
      disk_file_format = "VHDX"
      is_os_disk       = true
      is_dynamic       = true
    },
    {
      disk_id          = "6000C29c-41ff-3488-a9eb-d30f16a58561"
      disk_size_gb     = 200
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
  default     = "centralus"
  description = "The Azure region (custom location region). Must be a region where Microsoft.AzureStackHCI resources are available."
}

variable "machine_id" {
  type        = string
  default     = "/subscriptions/265ca7e5-909a-455d-9459-7c7041c1c37d/resourceGroups/saif-project-021826-rg/providers/Microsoft.OffAzure/VMwareSites/src28251site/machines/100-69-177-104-f1c605c7-d8ee-48df-a65a-9d3c1c60bc20_5023157d-5a3b-ef48-1e7d-bbc8885ce7d4"
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
      target_network_id = "/subscriptions/d41eb627-825d-4419-a14d-c6ad485f4110/resourceGroups/EDGECI-REGISTRATION-s46r1405-t8g6NRVO/providers/microsoft.azurestackhci/logicalnetworks/s46r1405-lnet"
      test_network_id   = "/subscriptions/d41eb627-825d-4419-a14d-c6ad485f4110/resourceGroups/EDGECI-REGISTRATION-s46r1405-t8g6NRVO/providers/microsoft.azurestackhci/logicalnetworks/s46r1405-tenant-lnet-201"
      selection_type    = "SelectedByUser"
    }
  ]
  description = "NICs to include for replication (from machine properties). Use this for POWER USER MODE."
}

variable "os_disk_id" {
  type        = string
  default     = "6000C29c-262c-2f47-4313-0869276a9574"
  description = "The OS disk ID of the source VM. Used for DEFAULT USER MODE when disks_to_include is not provided."
}

variable "os_disk_size_gb" {
  type        = number
  default     = 100
  description = "The OS disk size in GB for DEFAULT USER MODE. Used when disks_to_include is not provided."
}

variable "policy_name" {
  type        = string
  default     = "saif-project-08648replicationvaultVMwareToAzStackHCIpolicy"
  description = "The name of the replication policy"
}

variable "project_name" {
  type        = string
  default     = "saif-project-021826"
  description = "The name of the Azure Migrate project"
}

variable "replication_extension_name" {
  type        = string
  default     = "src27987replicationfabric-tgt28c21replicationfabric-MigReplicationExtn"
  description = "The name of the replication extension"
}

variable "replication_vault_id" {
  type        = string
  default     = "/subscriptions/265ca7e5-909a-455d-9459-7c7041c1c37d/resourceGroups/saif-project-021826-rg/providers/Microsoft.DataReplication/replicationVaults/saif-project-08648replicationvault"
  description = "The full resource ID of the replication vault"
}

variable "run_as_account_id" {
  type        = string
  default     = "/subscriptions/265ca7e5-909a-455d-9459-7c7041c1c37d/resourceGroups/saif-project-021826-rg/providers/Microsoft.OffAzure/VMwareSites/src28251site/runasaccounts/58093f44-117a-561b-be13-d751e1b22ca9"
  description = "The full resource ID of the run as account (from vCenter)"
}

variable "source_appliance_name" {
  type        = string
  default     = "src2"
  description = "The name prefix for the source appliance"
}

variable "source_fabric_agent_name" {
  type        = string
  default     = "src27987dra"
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
  default     = "tgt2"
  description = "The name prefix for the target appliance (from initialize variables)"
}

variable "target_fabric_agent_name" {
  type        = string
  default     = "tgt28c21dra"
  description = "The name of the target fabric DRA"
}

variable "target_hci_cluster_id" {
  type        = string
  default     = "/subscriptions/d41eb627-825d-4419-a14d-c6ad485f4110/resourceGroups/EDGECI-REGISTRATION-s46r1405-t8g6NRVO/providers/Microsoft.AzureStackHCI/clusters/s46r1405-cl"
  description = "The full resource ID of the target Azure Stack HCI cluster"
}

variable "target_resource_group_id" {
  type        = string
  default     = "/subscriptions/d41eb627-825d-4419-a14d-c6ad485f4110/resourceGroups/EDGECI-REGISTRATION-s46r1405-t8g6NRVO"
  description = "The full resource ID of the target resource group"
}

variable "target_storage_path_id" {
  type        = string
  default     = "/subscriptions/d41eb627-825d-4419-a14d-c6ad485f4110/resourceGroups/EDGECI-REGISTRATION-s46r1405-t8g6NRVO/providers/Microsoft.AzureStackHCI/storagecontainers/UserStorage1-358c690cfced472fae974ef257f1e531"
  description = "The full resource ID of the target storage path"
}

variable "target_virtual_switch_id" {
  type        = string
  default     = "/subscriptions/d41eb627-825d-4419-a14d-c6ad485f4110/resourceGroups/EDGECI-REGISTRATION-s46r1405-t8g6NRVO/providers/microsoft.azurestackhci/logicalnetworks/s46r1405-lnet"
  description = "The full resource ID of the target virtual switch/network"
}

variable "target_vm_cpu_cores" {
  type        = number
  default     = 2
  description = "Number of CPU cores for the target VM"
}

variable "target_vm_name" {
  type        = string
  default     = "LH-WS2022-11-migrated"
  description = "The name for the migrated VM on Azure Stack HCI"
}

variable "target_vm_ram_mb" {
  type        = number
  default     = 4096
  description = "Amount of RAM in MB for the target VM"
}
