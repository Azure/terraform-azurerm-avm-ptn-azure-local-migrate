variable "parent_id" {
  type        = string
  default     = "/subscriptions/265ca7e5-909a-455d-9459-7c7041c1c37d/resourceGroups/saif-project-021826-rg"
  description = "The resource ID of the resource group where the replication vault exists. Format: /subscriptions/{subscription-id}/resourceGroups/{resource-group-name}"
}

variable "force_remove" {
  type        = bool
  default     = false
  description = "Specifies whether the replication needs to be force removed. Use with caution as force removal may leave resources in an inconsistent state."
}

variable "location" {
  type        = string
  default     = "eastus"
  description = "Optional: The Azure region where resources will be deployed. If not specified, uses the resource group's location."
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Tags to apply to the resources"
}

variable "target_object_id" {
  type        = string
  default     = "/subscriptions/265ca7e5-909a-455d-9459-7c7041c1c37d/resourceGroups/saif-project-021826-rg/providers/Microsoft.DataReplication/replicationVaults/saif-project-08648replicationvault/protectedItems/100-69-177-104-f1c605c7-d8ee-48df-a65a-9d3c1c60bc20_50230032-a843-484c-a72b-28f60291b43e"
  description = "The protected item ARM ID for which replication needs to be disabled. Format: /subscriptions/{subscription-id}/resourceGroups/{resource-group}/providers/Microsoft.DataReplication/replicationVaults/{vault-name}/protectedItems/{item-name}"

  validation {
    condition     = can(regex("^/subscriptions/[^/]+/resourceGroups/[^/]+/providers/Microsoft\\.DataReplication/replicationVaults/[^/]+/protectedItems/[^/]+$", var.target_object_id))
    error_message = "target_object_id must be a valid protected item ARM ID in the format: /subscriptions/{subscription-id}/resourceGroups/{resource-group}/providers/Microsoft.DataReplication/replicationVaults/{vault-name}/protectedItems/{item-name}"
  }
}
