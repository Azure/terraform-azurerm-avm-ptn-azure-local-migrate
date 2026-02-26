variable "parent_id" {
  type        = string
  default     = "/subscriptions/265ca7e5-909a-455d-9459-7c7041c1c37d/resourceGroups/saif-project-021826-rg"
  description = "The resource ID of the resource group containing the Azure Migrate project. Format: /subscriptions/{subscription-id}/resourceGroups/{resource-group-name}"
}

variable "cache_storage_account_id" {
  type        = string
  default     = "/subscriptions/265ca7e5-909a-455d-9459-7c7041c1c37d/resourceGroups/saif-project-021826-rg/providers/Microsoft.Storage/storageAccounts/migratersa2220948737"
  description = "Optional: Existing cache storage account ID. If provided, the module will use this account instead of creating a new one. Use this when the environment was previously initialized (e.g., via CLI)."
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

variable "instance_type" {
  type        = string
  default     = "VMwareToAzStackHCI"
  description = "The migration instance type (VMwareToAzStackHCI or HyperVToAzStackHCI)"
}

variable "location" {
  type        = string
  default     = "eastus"
  description = "Optional: The Azure region where resources will be deployed. If not specified, uses the resource group's location."
}

variable "project_name" {
  type        = string
  default     = "saif-project-021826"
  description = "The name of the Azure Migrate project"
}

variable "recovery_point_history_minutes" {
  type        = number
  default     = 4320
  description = "Recovery point history retention in minutes"
}

variable "source_appliance_name" {
  type        = string
  default     = "src2"
  description = "The name of the source appliance (e.g., 'src2' for VMware). The module will automatically discover the corresponding fabric."
}

variable "source_fabric_id" {
  type        = string
  default     = "/subscriptions/265ca7e5-909a-455d-9459-7c7041c1c37d/resourceGroups/saif-project-021826-rg/providers/Microsoft.DataReplication/replicationFabrics/src27987replicationfabric"
  description = "Optional: Explicit source fabric ID. If not provided, it will be auto-discovered from source_appliance_name."
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
  description = "The name of the target appliance (e.g., 'tgt2' for Azure Stack HCI). The module will automatically discover the corresponding fabric."
}

variable "target_fabric_id" {
  type        = string
  default     = "/subscriptions/265ca7e5-909a-455d-9459-7c7041c1c37d/resourceGroups/saif-project-021826-rg/providers/Microsoft.DataReplication/replicationFabrics/tgt28c21replicationfabric"
  description = "Optional: Explicit target fabric ID. If not provided, it will be auto-discovered from target_appliance_name."
}
