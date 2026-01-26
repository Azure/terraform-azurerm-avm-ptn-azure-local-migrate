# --------------------------------------------------------------------------------------------
# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License. See License.txt in the project root for license information.
# --------------------------------------------------------------------------------------------
#
# Example: Create New Azure Migrate Project
# This example demonstrates how to create a new Azure Migrate project
#

terraform {
  required_version = ">= 1.5"

  required_providers {
    azapi = {
      source  = "azure/azapi"
      version = ">= 1.9, < 3.0"
    }
  }
}

provider "azapi" {
  subscription_id = var.subscription_id
}

# Create a new Azure Migrate project
module "create_migrate_project" {
  source = "../../"

  name                   = "create-project"
  resource_group_name    = var.resource_group_name
  instance_type          = var.instance_type
  operation_mode         = "discover"
  project_name           = var.project_name
  create_migrate_project = true # Set to true to create new project
  create_resource_group  = true # Set to true to create new resource group
  location               = var.location
  tags                   = var.tags
}
