# --------------------------------------------------------------------------------------------
# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License. See License.txt in the project root for license information.
# --------------------------------------------------------------------------------------------

variable "force_remove" {
  type        = bool
  default     = false
  description = "Specifies whether the replication needs to be force removed. Use with caution as force removal may leave resources in an inconsistent state."
}

variable "location" {
  type        = string
  default     = null
  description = "Optional: The Azure region. If not specified, uses the resource group's location."
}

variable "resource_group_name" {
  type        = string
  description = "The name of the resource group where the replication vault exists"
}

variable "subscription_id" {
  type        = string
  description = "The Azure subscription ID"
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Tags to apply to the resources"
}

variable "target_object_id" {
  type        = string
  description = "The protected item ARM ID for which replication needs to be disabled. Format: /subscriptions/{subscription-id}/resourceGroups/{resource-group}/providers/Microsoft.DataReplication/replicationVaults/{vault-name}/protectedItems/{item-name}"

  validation {
    condition     = can(regex("^/subscriptions/[^/]+/resourceGroups/[^/]+/providers/Microsoft\\.DataReplication/replicationVaults/[^/]+/protectedItems/[^/]+$", var.target_object_id))
    error_message = "target_object_id must be a valid protected item ARM ID in the format: /subscriptions/{subscription-id}/resourceGroups/{resource-group}/providers/Microsoft.DataReplication/replicationVaults/{vault-name}/protectedItems/{item-name}"
  }
}
