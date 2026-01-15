# --------------------------------------------------------------------------------------------
# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License. See License.txt in the project root for license information.
# --------------------------------------------------------------------------------------------

variable "app_consistent_frequency_minutes" {
  type        = number
  default     = 240
  description = "Application-consistent snapshot frequency in minutes"
}

variable "crash_consistent_frequency_minutes" {
  type        = number
  default     = 60
  description = "Crash-consistent snapshot frequency in minutes"
}

variable "instance_type" {
  type        = string
  default     = "VMwareToAzStackHCI"
  description = "The migration instance type (VMwareToAzStackHCI or HyperVToAzStackHCI)"
}

variable "location" {
  type        = string
  default     = null
  description = "Optional: The Azure region where resources will be deployed. If not specified, uses the resource group's location."
}

variable "project_name" {
  type        = string
  default     = "saif-project-011326"
  description = "The name of the Azure Migrate project"
}

variable "recovery_point_history_minutes" {
  type        = number
  default     = 4320
  description = "Recovery point history retention in minutes"
}

variable "resource_group_name" {
  type        = string
  default     = "saif-project-011326-rg"
  description = "The name of the resource group containing the Azure Migrate project"
}

variable "source_appliance_name" {
  type        = string
  default     = "src"
  description = "The name of the source appliance (e.g., 'src' for VMware or HyperV). The module will automatically discover the corresponding fabric."
}

variable "source_fabric_id" {
  type        = string
  default     = null
  description = "Optional: Explicit source fabric ID. If not provided, it will be auto-discovered from source_appliance_name."
}

variable "subscription_id" {
  type        = string
  default     = "de3c4d5e-af08-451a-a873-438d86ab6f4b"
  description = "The Azure subscription ID where resources will be deployed"
}

variable "tags" {
  type = map(string)
  default = {
    Environment = "Production"
    Purpose     = "HCI Migration Infrastructure"
    Owner       = "IT Team"
  }
  description = "Tags to apply to all resources"
}

variable "target_appliance_name" {
  type        = string
  default     = "tgt"
  description = "The name of the target appliance (e.g., 'tgt' for Azure Stack HCI). The module will automatically discover the corresponding fabric."
}

variable "target_fabric_id" {
  type        = string
  default     = null
  description = "Optional: Explicit target fabric ID. If not provided, it will be auto-discovered from target_appliance_name."
}
