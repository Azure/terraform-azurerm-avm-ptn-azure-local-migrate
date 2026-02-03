variable "parent_id" {
  type        = string
  description = "The resource ID of the resource group where the replication vault exists. Format: /subscriptions/{subscription-id}/resourceGroups/{resource-group-name}"
}

variable "force_remove" {
  type        = bool
  default     = false
  description = "Specifies whether the replication needs to be force removed. Use with caution as force removal may leave resources in an inconsistent state."
}

variable "location" {
  type        = string
  default     = "westus2"
  description = "Optional: The Azure region where resources will be deployed. If not specified, uses the resource group's location."
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Tags to apply to the resources"
}

variable "target_object_id" {
  type        = string
  default     = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/my-migrate-project-rg/providers/Microsoft.DataReplication/replicationVaults/myprojectreplicationvault/protectedItems/my-vm-name"
  description = "The protected item ARM ID for which replication needs to be disabled. Format: /subscriptions/{subscription-id}/resourceGroups/{resource-group}/providers/Microsoft.DataReplication/replicationVaults/{vault-name}/protectedItems/{item-name}"

  validation {
    condition     = can(regex("^/subscriptions/[^/]+/resourceGroups/[^/]+/providers/Microsoft\\.DataReplication/replicationVaults/[^/]+/protectedItems/[^/]+$", var.target_object_id))
    error_message = "target_object_id must be a valid protected item ARM ID in the format: /subscriptions/{subscription-id}/resourceGroups/{resource-group}/providers/Microsoft.DataReplication/replicationVaults/{vault-name}/protectedItems/{item-name}"
  }
}
