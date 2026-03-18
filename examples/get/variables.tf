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

variable "parent_id" {
  type        = string
  default     = "/subscriptions/265ca7e5-909a-455d-9459-7c7041c1c37d/resourceGroups/saif-project-021826-rg"
  description = "The resource ID of the resource group containing the Azure Migrate project. Format: /subscriptions/{subscription-id}/resourceGroups/{resource-group-name}"
}

variable "project_name" {
  type        = string
  default     = "saif-project-021826"
  description = "The name of the Azure Migrate project"
}

variable "protected_item_id" {
  type        = string
  default     = "/subscriptions/265ca7e5-909a-455d-9459-7c7041c1c37d/resourceGroups/saif-project-021826-rg/providers/Microsoft.DataReplication/replicationVaults/saif-project-08648replicationvault/protectedItems/100-69-177-104-f1c605c7-d8ee-48df-a65a-9d3c1c60bc20_50230032-a843-484c-a72b-28f60291b43e"
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
