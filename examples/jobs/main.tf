# --------------------------------------------------------------------------------------------
# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License. See License.txt in the project root for license information.
# --------------------------------------------------------------------------------------------
#
# Example: Get Replication Jobs
# This example demonstrates how to retrieve replication job status
#

terraform {
  required_version = ">= 1.5"

  required_providers {
    azapi = {
      source  = "azure/azapi"
      version = ">= 1.9, < 3.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.71, < 5.0"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}

# Get replication jobs
module "replication_jobs" {
  source = "../../"

  name                = "replication-jobs"
  resource_group_name = var.resource_group_name
  instance_type       = var.instance_type
  operation_mode      = "jobs"
  project_name        = var.project_name
  # Use explicit vault ID
  replication_vault_id = var.replication_vault_id
  tags                 = var.tags
}

