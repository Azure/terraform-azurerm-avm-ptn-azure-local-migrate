# --------------------------------------------------------------------------------------------
# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License. See License.txt in the project root for license information.
# --------------------------------------------------------------------------------------------

variable "subscription_id" {
  type        = string
  description = "The Azure subscription ID where resources will be deployed"
  default     = "f6f66a94-f184-45da-ac12-ffbfd8a6eb29"
}

variable "resource_group_name" {
  type        = string
  description = "The name of the resource group containing the Azure Migrate project"
  default     = "saif-project-120126-rg"
}

variable "project_name" {
  type        = string
  description = "The name of the Azure Migrate project (optional, used for job tracking)"
  default     = "saif-project-120126"
}

variable "location" {
  type        = string
  description = "The Azure region where resources will be deployed"
  default     = "australiaeast"
}

variable "instance_type" {
  type        = string
  description = "The migration instance type (VMwareToAzStackHCI or HyperVToAzStackHCI)"
  default     = "VMwareToAzStackHCI"
}

variable "target_object_id" {
  type        = string
  description = "The full resource ID of the protected item to remove from replication"
  default     = "/subscriptions/f6f66a94-f184-45da-ac12-ffbfd8a6eb29/resourceGroups/saif-project-120126-rg/providers/Microsoft.DataReplication/replicationVaults/saif-project-16712replicationvault/protectedItems/100-69-177-104-f0d9ffab-ffc9-4567-84a3-792f2f01fc57_5023a8b8-6ecc-b7ad-4e88-8db9f80f737c"
}

variable "force_remove" {
  type        = bool
  description = "Whether to force remove the protected item (use when normal removal fails)"
  default     = false
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to resources"
  default = {
    Environment = "Test"
    Purpose     = "RemoveReplication"
  }
}
