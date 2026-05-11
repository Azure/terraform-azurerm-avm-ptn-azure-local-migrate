variable "location" {
  type        = string
  description = "Azure region for managed resources."
}

variable "parent_id" {
  type        = string
  description = "Resource group ID containing the Azure Migrate project. Format: /subscriptions/{sub}/resourceGroups/{rg}"
}

variable "parent_id" {
  type        = string
  default     = "/subscriptions/265ca7e5-909a-455d-9459-7c7041c1c37d/resourceGroups/saif-project-021826-rg"
  description = "The resource ID of the resource group containing the Azure Migrate project. Format: /subscriptions/{subscription-id}/resourceGroups/{resource-group-name}"
}

variable "project_name" {
  type        = string
  description = "Azure Migrate project name (matches `-ProjectName` in PowerShell)."
}

variable "source_appliance_name" {
  type        = string
  description = "Source appliance name (matches `-SourceApplianceName` in PowerShell)."
}

variable "target_appliance_name" {
  type        = string
  description = "Target appliance name (matches `-TargetApplianceName` in PowerShell)."
}
