# --------------------------------------------------------------------------------------------
# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License. See License.txt in the project root for license information.
# --------------------------------------------------------------------------------------------
#
# Example: Get Protected Item Details
# This example demonstrates how to retrieve details of a protected (replicating) VM
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

# Get protected item details
module "get_protected_item" {
  source = "../../"

  name                = "get-protected-item"
  resource_group_name = var.resource_group_name
  instance_type       = var.instance_type
  operation_mode      = "get"
  project_name        = var.project_name
  # Get by ID
  protected_item_id = var.protected_item_id
  tags              = var.tags
}






