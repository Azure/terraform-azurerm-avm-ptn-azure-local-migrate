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
  description = "The name of the Azure Migrate project"
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

variable "job_name" {
  type        = string
  description = "The name of a specific job to retrieve. If null, lists all jobs."
  default     = null
}

variable "replication_vault_id" {
  type        = string
  description = "The full resource ID of the replication vault (optional, derived from project if not provided)"
  default     = "/subscriptions/f6f66a94-f184-45da-ac12-ffbfd8a6eb29/resourceGroups/saif-project-120126-rg/providers/Microsoft.DataReplication/replicationVaults/saif-project-16712replicationvault"
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to resources"
  default = {
    Environment = "Test"
    Purpose     = "ReplicationJobs"
  }
}
