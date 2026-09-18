variable "parent_id" {
  type        = string
  description = "The resource ID of the resource group containing the Azure Migrate project. Format: /subscriptions/{subscription-id}/resourceGroups/{resource-group-name}"
}

variable "project_name" {
  type        = string
  default     = "<migrate-project-name>"
  description = "The name of the Azure Migrate project"
}

variable "tags" {
  type = map(string)
  default = {
    Environment = "Test"
    Purpose     = "Discovery"
  }
  description = "Tags to apply to all resources"
}

variable "enable_telemetry" {
  type        = bool
  default     = false
  description = <<DESCRIPTION
This variable controls whether or not telemetry is enabled for the module.
For more information see <https://aka.ms/avm/telemetryinfo>.
If it is set to false, then no telemetry will be collected.
DESCRIPTION
}
