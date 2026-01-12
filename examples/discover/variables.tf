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
  default     = "saif-project-010626-rg"
}

variable "project_name" {
  type        = string
  description = "The name of the Azure Migrate project"
  default     = "saif-project-010626"
}

variable "location" {
  type        = string
  description = "The Azure region where resources will be deployed"
  default     = "eastus"
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
