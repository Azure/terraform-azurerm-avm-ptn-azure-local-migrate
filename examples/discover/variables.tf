# --------------------------------------------------------------------------------------------
# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License. See License.txt in the project root for license information.
# --------------------------------------------------------------------------------------------

variable "subscription_id" {
  type        = string
  description = "The Azure subscription ID where resources will be deployed"
  default     = "de3c4d5e-af08-451a-a873-438d86ab6f4b"
}

variable "resource_group_name" {
  type        = string
  description = "The name of the resource group containing the Azure Migrate project"
  default     = "saif-project-011326-rg"
}

variable "project_name" {
  type        = string
  description = "The name of the Azure Migrate project"
  default     = "saif-project-011326"
}

variable "location" {
  type        = string
  description = "Optional: The Azure region. If not specified, uses the resource group's location."
  default     = null
}

variable "instance_type" {
  type        = string
  description = "The migration instance type (VMwareToAzStackHCI or HyperVToAzStackHCI)"
  default     = "VMwareToAzStackHCI"
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to all resources"
  default = {
    Environment = "Test"
    Purpose     = "Discovery"
  }
}
