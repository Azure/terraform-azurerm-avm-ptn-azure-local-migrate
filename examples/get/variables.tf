variable "parent_id" {
  type        = string
  description = "The resource ID of the resource group containing the Azure Migrate project. Format: /subscriptions/{subscription-id}/resourceGroups/{resource-group-name}"
}

variable "location" {
  type        = string
  default     = "eastus"
  description = "Optional: The Azure region where resources will be deployed. If not specified, uses the resource group's location."
}

variable "parent_id" {
  type        = string
  default     = "/subscriptions/265ca7e5-909a-455d-9459-7c7041c1c37d/resourceGroups/saif-project-021826-rg"
  description = "The resource ID of the resource group containing the Azure Migrate project. Format: /subscriptions/{subscription-id}/resourceGroups/{resource-group-name}"
}

variable "project_name" {
  type        = string
  default     = "<migrate-project-name>"
  description = "The name of the Azure Migrate project"
}

variable "protected_item_id" {
  type        = string
  default     = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/<rg>/providers/Microsoft.DataReplication/replicationVaults/<vault>/protectedItems/<protected-item>"
  description = "The full resource ID of the protected item to retrieve"
}

variable "tags" {
  type = map(string)
  default = {
    Environment = "Test"
    Purpose     = "GetProtectedItem"
  }
  description = "Tags to apply to resources"
}
