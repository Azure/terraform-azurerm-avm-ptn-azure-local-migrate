# ========================================
# COMMON INPUTS
# ========================================

variable "parent_id" {
  type        = string
  description = "Resource ID of the resource group containing the Azure Migrate project. Format: /subscriptions/{sub}/resourceGroups/{rg}"
}

variable "project_name" {
  type        = string
  description = "The name of the Azure Migrate project."
}

variable "source_appliance_name" {
  type        = string
  description = "The name of the source appliance."
}

variable "target_appliance_name" {
  type        = string
  description = "The name of the target appliance."
}

# ========================================
# INITIALIZE (STEP 0)
# ========================================

variable "skip_initialize" {
  type        = bool
  default     = true
  description = "Skip the initialize step when the replication vault/policy/extension already exist."
}

variable "replication_vault_id" {
  type        = string
  default     = null
  description = "Replication vault ID. Required when `skip_initialize = true`. When omitted, it is auto-discovered from the migrate project."
}

# ========================================
# REPLICATE (STEP 1)
# ========================================

variable "custom_location_id" {
  type        = string
  description = "Arc custom location ARM ID for the Azure Local cluster."
}

variable "run_as_account_id" {
  type        = string
  description = "Run-as account ARM ID (from vCenter for VMware sources)."
}

variable "target_hci_cluster_id" {
  type        = string
  description = "Target Azure Stack HCI / Azure Local cluster ARM ID."
}

variable "target_resource_group_id" {
  type        = string
  description = "Target resource group ARM ID where migrated VMs will be created."
}

variable "target_storage_path_id" {
  type        = string
  description = "Target storage container ARM ID for VHDX placement."
}

variable "target_virtual_switch_id" {
  type        = string
  description = "Target logical network / virtual switch ARM ID."
}

# ========================================
# MIGRATE (STEP 3)
# ========================================

variable "shutdown_source_vm" {
  type        = bool
  default     = true
  description = "Whether to shut the source VM down before planned failover."
}

# ========================================
# VMs TO REPLICATE
# ========================================

variable "vms" {
  type = map(object({
    machine_id     = string
    target_vm_name = string
    os_disk_id     = string
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
      selection_type    = optional(string, "SelectedByUser")
    })), null)
  }))
  description = "Map of VMs to replicate. Each key is a friendly name used in module addressing."
}

# ========================================
# TAGS
# ========================================

variable "tags" {
  type        = map(string)
  default     = null
  description = "Tags to apply to managed resources."
}
