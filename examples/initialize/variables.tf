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

variable "source_fabric_id" {
  type        = string
  description = "The full resource ID of the source replication fabric (obtained from Azure Migrate)"
  default     = "/subscriptions/f6f66a94-f184-45da-ac12-ffbfd8a6eb29/resourceGroups/saif-project-010626-rg/providers/Microsoft.DataReplication/replicationFabrics/src71e9replicationfabric"
}

variable "target_fabric_id" {
  type        = string
  description = "The full resource ID of the target replication fabric (obtained from Azure Migrate)"
  default     = "/subscriptions/f6f66a94-f184-45da-ac12-ffbfd8a6eb29/resourceGroups/saif-project-010626-rg/providers/Microsoft.DataReplication/replicationFabrics/tgt77a5replicationfabric"
}

variable "location" {
  type        = string
  description = "The Azure region where resources will be deployed"
  default     = "eastus"
}

variable "source_appliance_name" {
  type        = string
  description = "The name prefix for the source appliance"
  default     = "src"
}

variable "target_appliance_name" {
  type        = string
  description = "The name prefix for the target appliance"
  default     = "tgt"
}

variable "app_consistent_frequency_minutes" {
  type        = number
  description = "Application-consistent snapshot frequency in minutes"
  default     = 240
}

variable "crash_consistent_frequency_minutes" {
  type        = number
  description = "Crash-consistent snapshot frequency in minutes"
  default     = 60
}

variable "recovery_point_history_minutes" {
  type        = number
  description = "Recovery point history retention in minutes"
  default     = 4320
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
    Environment = "Production"
    Purpose     = "HCI Migration Infrastructure"
    Owner       = "IT Team"
  }
}
