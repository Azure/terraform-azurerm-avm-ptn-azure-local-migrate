variable "parent_id" {
  type        = string
  description = "The resource ID of the resource group containing the Azure Migrate project. Format: /subscriptions/{subscription-id}/resourceGroups/{resource-group-name}"
}

variable "instance_type" {
  type        = string
  default     = "VMwareToAzStackHCI"
  description = "The migration instance type (VMwareToAzStackHCI or HyperVToAzStackHCI)"
}

variable "location" {
  type        = string
  default     = "westus2"
  description = "Optional: The Azure region where resources will be deployed. If not specified, uses the resource group's location."
}

variable "project_name" {
  type        = string
  default     = "saif-project-012726"
  description = "The name of the Azure Migrate project"
}

variable "protected_item_id" {
  type        = string
  default     = "/subscriptions/f6f66a94-f184-45da-ac12-ffbfd8a6eb29/resourceGroups/saif-project-012726-rg/providers/Microsoft.DataReplication/replicationVaults/saif-project-01424replicationvault/protectedItems/100-69-177-104-36bf83bc-c03b-4c08-853c-187db9aa17e8_50232086-5a0d-7205-68e2-bc2391e7a0a7"
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
