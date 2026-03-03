# ========================================
# COMMON VARIABLES
# ========================================

variable "parent_id" {
  type        = string
  default     = "/subscriptions/265ca7e5-909a-455d-9459-7c7041c1c37d/resourceGroups/saif-project-021826-rg"
  description = "The resource ID of the resource group containing the Azure Migrate project. Format: /subscriptions/{subscription-id}/resourceGroups/{resource-group-name}"
}

variable "instance_type" {
  type        = string
  default     = "VMwareToAzStackHCI"
  description = "The migration instance type (VMwareToAzStackHCI or HyperVToAzStackHCI)"
}

variable "location" {
  type        = string
  default     = "eastus"
  description = "The Azure region (custom location region). Must be a region where Microsoft.AzureStackHCI resources are available."
}

variable "project_name" {
  type        = string
  default     = "saif-project-021826"
  description = "The name of the Azure Migrate project"
}

variable "source_appliance_name" {
  type        = string
  default     = "src2"
  description = "The name prefix for the source appliance"
}

variable "target_appliance_name" {
  type        = string
  default     = "tgt2"
  description = "The name prefix for the target appliance"
}

variable "tags" {
  type = map(string)
  default = {
    Environment = "Production"
    Purpose     = "HCI Migration End-to-End"
    Owner       = "IT Team"
  }
  description = "Tags to apply to all resources"
}

# ========================================
# INITIALIZE VARIABLES (Step 0)
# ========================================

variable "skip_initialize" {
  type        = bool
  default     = true
  description = "Set to true to skip initialization (when replication infrastructure already exists). When false, the module will create vault, policy, and extension."
}

variable "cache_storage_account_id" {
  type        = string
  default     = "/subscriptions/265ca7e5-909a-455d-9459-7c7041c1c37d/resourceGroups/saif-project-021826-rg/providers/Microsoft.Storage/storageAccounts/migratersa2220948737"
  description = "Optional: Existing cache storage account ID. If provided, the module will use this account instead of creating a new one."
}

variable "source_fabric_id" {
  type        = string
  default     = "/subscriptions/265ca7e5-909a-455d-9459-7c7041c1c37d/resourceGroups/saif-project-021826-rg/providers/Microsoft.DataReplication/replicationFabrics/src27987replicationfabric"
  description = "Optional: Explicit source fabric ID. If not provided, it will be auto-discovered from source_appliance_name."
}

variable "target_fabric_id" {
  type        = string
  default     = "/subscriptions/265ca7e5-909a-455d-9459-7c7041c1c37d/resourceGroups/saif-project-021826-rg/providers/Microsoft.DataReplication/replicationFabrics/tgt28c21replicationfabric"
  description = "Optional: Explicit target fabric ID. If not provided, it will be auto-discovered from target_appliance_name."
}

variable "app_consistent_frequency_minutes" {
  type        = number
  default     = 240
  description = "Application-consistent snapshot frequency in minutes"
}

variable "crash_consistent_frequency_minutes" {
  type        = number
  default     = 60
  description = "Crash-consistent snapshot frequency in minutes"
}

variable "recovery_point_history_minutes" {
  type        = number
  default     = 4320
  description = "Recovery point history retention in minutes"
}

# ========================================
# REPLICATION VARIABLES (Step 1)
# ========================================

variable "custom_location_id" {
  type        = string
  default     = "/subscriptions/d41eb627-825d-4419-a14d-c6ad485f4110/resourceGroups/EDGECI-REGISTRATION-s46r1405-t8g6NRVO/providers/Microsoft.ExtendedLocation/customLocations/s46r1405-cl-customLocation"
  description = "The full resource ID of the Azure Stack HCI custom location"
}

variable "policy_name" {
  type        = string
  default     = "saif-project-08648replicationvaultVMwareToAzStackHCIpolicy"
  description = "The name of the replication policy. Required when skip_initialize = true."
}

variable "replication_extension_name" {
  type        = string
  default     = "src27987replicationfabric-tgt28c21replicationfabric-MigReplicationExtn"
  description = "The name of the replication extension. Required when skip_initialize = true."
}

variable "replication_vault_id" {
  type        = string
  default     = "/subscriptions/265ca7e5-909a-455d-9459-7c7041c1c37d/resourceGroups/saif-project-021826-rg/providers/Microsoft.DataReplication/replicationVaults/saif-project-08648replicationvault"
  description = "The full resource ID of the replication vault. Required when skip_initialize = true."
}

variable "run_as_account_id" {
  type        = string
  default     = "/subscriptions/265ca7e5-909a-455d-9459-7c7041c1c37d/resourceGroups/saif-project-021826-rg/providers/Microsoft.OffAzure/VMwareSites/src28251site/runasaccounts/58093f44-117a-561b-be13-d751e1b22ca9"
  description = "The full resource ID of the run as account (from vCenter)"
}

variable "source_fabric_agent_name" {
  type        = string
  default     = "src27987dra"
  description = "The name of the source fabric DRA"
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

# ========================================
# VMs TO REPLICATE (Step 1)
# ========================================
# Map of VMs to replicate. Each key is a friendly name used for module addressing.

variable "vms" {
  type = map(object({
    machine_id            = string
    target_vm_name        = string
    os_disk_id            = string
    os_disk_size_gb       = optional(number, 40)
    hyperv_generation     = optional(string, "2")
    source_vm_cpu_cores   = optional(number, 4)
    source_vm_ram_mb      = optional(number, 4096)
    target_vm_cpu_cores   = optional(number, 4)
    target_vm_ram_mb      = optional(number, 4096)
    is_dynamic_memory_enabled = optional(bool, false)
    nic_id                = optional(string, null)
    disks_to_include = list(object({
      disk_id                   = string
      disk_size_gb              = number
      disk_file_format          = optional(string, "VHDX")
      is_os_disk                = optional(bool, false)
      is_dynamic                = optional(bool, true)
      disk_physical_sector_size = optional(number, 512)
    }))
    nics_to_include = optional(list(object({
      nic_id            = string
      target_network_id = string
      test_network_id   = optional(string)
      selection_type    = optional(string, "SelectedByUser")
    })), null)
  }))
  default = {
    # VM 1: Ubuntu Linux (EFI, Gen2) - 3 disks, 4 vCPU, 4 GB RAM
    "test-vm4-ubuntuvm64efi-pnu" = {
      machine_id        = "/subscriptions/265ca7e5-909a-455d-9459-7c7041c1c37d/resourceGroups/saif-project-021826-rg/providers/Microsoft.OffAzure/VMwareSites/src28251site/machines/100-69-177-104-f1c605c7-d8ee-48df-a65a-9d3c1c60bc20_5023ed01-02d7-153f-6955-f6367f2667e1"
      target_vm_name    = "test-vm4-ubuntuvm64efi-pnu-migrated"
      os_disk_id        = "6000C290-a4d0-e5ea-bad5-4e993df22e3b"
      os_disk_size_gb   = 40
      hyperv_generation = "2"
      source_vm_cpu_cores = 4
      source_vm_ram_mb    = 4096
      target_vm_cpu_cores = 4
      target_vm_ram_mb    = 4096
      disks_to_include = [
        {
          disk_id          = "6000C290-a4d0-e5ea-bad5-4e993df22e3b"
          disk_size_gb     = 40
          disk_file_format = "VHDX"
          is_os_disk       = true
          is_dynamic       = true
        },
        {
          disk_id          = "6000C29a-bcb7-a62b-7ed0-0c78f3dc1f80"
          disk_size_gb     = 16
          disk_file_format = "VHDX"
          is_os_disk       = false
          is_dynamic       = true
        },
        {
          disk_id          = "6000C290-d280-fcaa-b6a9-f65964e61f10"
          disk_size_gb     = 10
          disk_file_format = "VHDX"
          is_os_disk       = false
          is_dynamic       = true
        }
      ]
      nics_to_include = [
        {
          nic_id            = "4000"
          target_network_id = "/subscriptions/d41eb627-825d-4419-a14d-c6ad485f4110/resourceGroups/EDGECI-REGISTRATION-s46r1405-t8g6NRVO/providers/microsoft.azurestackhci/logicalnetworks/s46r1405-lnet"
          test_network_id   = "/subscriptions/d41eb627-825d-4419-a14d-c6ad485f4110/resourceGroups/EDGECI-REGISTRATION-s46r1405-t8g6NRVO/providers/microsoft.azurestackhci/logicalnetworks/s46r1405-tenant-lnet-201"
          selection_type    = "SelectedByUser"
        }
      ]
    }

    # VM 2: Windows Server 2008 R2 (BIOS, Gen1) - 1 disk, 2 vCPU, 4 GB RAM
    "test-vm5-win2008r2-ccy" = {
      machine_id        = "/subscriptions/265ca7e5-909a-455d-9459-7c7041c1c37d/resourceGroups/saif-project-021826-rg/providers/Microsoft.OffAzure/VMwareSites/src28251site/machines/100-69-177-104-f1c605c7-d8ee-48df-a65a-9d3c1c60bc20_502305a2-c0ed-80f5-6802-9829dd78ddc2"
      target_vm_name    = "test-vm5-win2008r2-ccy-migrated"
      os_disk_id        = "6000C29a-d7c9-dfb7-e74b-c4c104c9075c"
      os_disk_size_gb   = 39
      hyperv_generation = "1"
      source_vm_cpu_cores = 2
      source_vm_ram_mb    = 4096
      target_vm_cpu_cores = 2
      target_vm_ram_mb    = 4096
      disks_to_include = [
        {
          disk_id          = "6000C29a-d7c9-dfb7-e74b-c4c104c9075c"
          disk_size_gb     = 39
          disk_file_format = "VHDX"
          is_os_disk       = true
          is_dynamic       = true
        }
      ]
      nics_to_include = [
        {
          nic_id            = "4000"
          target_network_id = "/subscriptions/d41eb627-825d-4419-a14d-c6ad485f4110/resourceGroups/EDGECI-REGISTRATION-s46r1405-t8g6NRVO/providers/microsoft.azurestackhci/logicalnetworks/s46r1405-lnet"
          test_network_id   = "/subscriptions/d41eb627-825d-4419-a14d-c6ad485f4110/resourceGroups/EDGECI-REGISTRATION-s46r1405-t8g6NRVO/providers/microsoft.azurestackhci/logicalnetworks/s46r1405-tenant-lnet-201"
          selection_type    = "SelectedByUser"
        }
      ]
    }
  }
  description = "Map of VMs to replicate. Each key is a friendly name, and the value contains all per-VM configuration."
}

# ========================================
# MIGRATION CONTROL VARIABLES (Step 3)
# ========================================

variable "shutdown_source_vm" {
  type        = bool
  default     = true
  description = "Whether to shutdown the source VM before migration (recommended for production migrations)"
}
