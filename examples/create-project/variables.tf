# --------------------------------------------------------------------------------------------
# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License. See License.txt in the project root for license information.
# --------------------------------------------------------------------------------------------

variable "instance_type" {
  type        = string
  default     = "VMwareToAzStackHCI"
  description = "The migration instance type (VMwareToAzStackHCI or HyperVToAzStackHCI)"
}

variable "location" {
  type        = string
  default     = "westus2"
  description = "The Azure region where the Migrate project will be created. Note: Not all regions support Azure Migrate projects. Supported regions include: centralus, westus2, northeurope, westeurope, etc."
}

variable "project_name" {
  type        = string
  default     = "saif-project-012726"
  description = "The name of the new Azure Migrate project to create"
}

variable "resource_group_name" {
  type        = string
  default     = "saif-project-012726-rg"
  description = "The name of the resource group where the Migrate project will be created"
}

variable "subscription_id" {
  type        = string
  default     = "f6f66a94-f184-45da-ac12-ffbfd8a6eb29"
  description = "The Azure subscription ID where resources will be deployed"
}

variable "tags" {
  type = map(string)
  default = {
    Environment = "Production"
    Purpose     = "MigrateProject"
    ManagedBy   = "Terraform"
  }
  description = "Tags to apply to the Azure Migrate project"
}
