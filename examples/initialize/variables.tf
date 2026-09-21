variable "parent_id" {
  type        = string
  description = "Resource group ID containing the Azure Migrate project. Format: /subscriptions/{sub}/resourceGroups/{rg}"
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

variable "enable_telemetry" {
  type        = bool
  default     = true
  description = <<DESCRIPTION
This variable controls whether or not telemetry is enabled for the module.
For more information see <https://aka.ms/avm/telemetryinfo>.
If it is set to false, then no telemetry will be collected.
DESCRIPTION
}
