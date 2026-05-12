variable "parent_id" {
  type        = string
  description = "The resource ID of the resource group containing the Azure Migrate project. Format: /subscriptions/{subscription-id}/resourceGroups/{resource-group-name}"
}

variable "location" {
  type        = string
  default     = "eastus"
  description = "Optional: The Azure region where resources will be deployed. If not specified, uses the resource group's location."
}

variable "project_name" {
  type        = string
  default     = "<migrate-project-name>"
  description = "The name of the Azure Migrate project (used to auto-discover vault)"
}

variable "tags" {
  type = map(string)
  default = {
    Environment = "Test"
    Purpose     = "ListProtectedItems"
  }
  description = "Tags to apply to resources"
}
