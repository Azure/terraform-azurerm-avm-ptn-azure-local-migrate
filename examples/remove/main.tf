# --------------------------------------------------------------------------------------------
# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License. See License.txt in the project root for license information.
# --------------------------------------------------------------------------------------------
#
# Example: Remove VM Replication
# This example demonstrates how to remove/disable replication for a protected item
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

# Remove replication for a protected item
module "remove_replication" {
  source = "../../"

  name                = "remove-replication"
  resource_group_name = var.resource_group_name
  force_remove        = var.force_remove
  location            = var.location
  operation_mode      = "remove"
  tags                = var.tags
  target_object_id    = var.target_object_id
}
