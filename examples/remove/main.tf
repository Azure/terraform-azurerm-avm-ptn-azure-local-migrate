# --------------------------------------------------------------------------------------------
# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License. See License.txt in the project root for license information.
# --------------------------------------------------------------------------------------------
#
# Example: Remove Protected Item (Disable Replication)
# This example demonstrates how to stop replication for a protected VM
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

# Remove protected item (disable replication)
module "remove_replication" {
  source = "../../"

  location            = var.location
  name                = "remove-replication"
  resource_group_name = var.resource_group_name
  instance_type       = var.instance_type
  operation_mode      = "remove"
  project_name        = var.project_name

  # Protected item to remove
  target_object_id = var.target_object_id

  # Force remove (use when normal removal fails)
  force_remove = var.force_remove

  tags = var.tags
}
