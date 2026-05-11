variable "custom_location_id" {
  type        = string
  description = "Arc custom location ARM ID for the Azure Local cluster."
}

variable "location" {
  type        = string
  description = "Azure region for managed resources."
}

variable "machine_id" {
  type        = string
  description = "Discovered machine ID (matches `-MachineId` in PowerShell)."
}

variable "os_disk_id" {
  type        = string
  description = "Source disk ID containing the OS (matches `-OSDiskID` in PowerShell)."
}

variable "parent_id" {
  type        = string
  description = "Resource group ID containing the Azure Migrate project."
}

variable "project_name" {
  type        = string
  description = "Azure Migrate project name."
}

variable "source_appliance_name" {
  type        = string
  description = "Source appliance name."
}

variable "target_appliance_name" {
  type        = string
  description = "Target appliance name."
}

variable "target_hci_cluster_id" {
  type        = string
  description = "Target Azure Local (HCI) cluster ARM ID."
}

variable "target_resource_group_id" {
  type        = string
  description = "Resource group for the failed-over Azure Local VM (matches `-TargetResourceGroupId`)."
}

variable "target_storage_path_id" {
  type        = string
  description = "Target storage path (CSV) ARM ID on Azure Local (matches `-TargetStoragePathId`)."
}

variable "target_virtual_switch_id" {
  type        = string
  description = "Target virtual switch on Azure Local (matches `-TargetVirtualSwitch`)."
}

variable "target_vm_name" {
  type        = string
  description = "Name of the VM after failover (matches `-TargetVMName`)."
}
