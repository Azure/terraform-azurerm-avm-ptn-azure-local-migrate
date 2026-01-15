# --------------------------------------------------------------------------------------------
# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License. See License.txt in the project root for license information.
# --------------------------------------------------------------------------------------------

variable "instance_type" {
  type        = string
  default     = "VMwareToAzStackHCI"
  description = "The migration instance type (VMwareToAzStackHCI or HyperVToAzStackHCI)"
}

variable "project_name" {
  type        = string
  default     = "saif-project-120126"
  description = "The name of the Azure Migrate project"
}

variable "protected_item_id" {
  type        = string
  default     = "/subscriptions/f6f66a94-f184-45da-ac12-ffbfd8a6eb29/resourceGroups/saif-project-120126-rg/providers/Microsoft.DataReplication/replicationVaults/saif-project-16712replicationvault/protectedItems/100-69-177-104-f0d9ffab-ffc9-4567-84a3-792f2f01fc57_5023a8b8-6ecc-b7ad-4e88-8db9f80f737c"
  description = "The full resource ID of the protected item to retrieve"
}

variable "resource_group_name" {
  type        = string
  default     = "saif-project-120126-rg"
  description = "The name of the resource group containing the Azure Migrate project"
}

variable "subscription_id" {
  type        = string
  default     = "f6f66a94-f184-45da-ac12-ffbfd8a6eb29"
  description = "The Azure subscription ID where resources will be deployed"
}

variable "tags" {
  type = map(string)
  default = {
    Environment = "Test"
    Purpose     = "GetProtectedItem"
  }
  description = "Tags to apply to resources"
}
