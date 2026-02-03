# Example: Create New Azure Migrate Project
# This example demonstrates how to create a new Azure Migrate project
# Note: The resource group must already exist. Use parent_id to specify it.

terraform {
  required_version = ">= 1.9"

  required_providers {
    azapi = {
      source  = "azure/azapi"
      version = "~> 2.4"
    }
  }
}

provider "azapi" {}

# Create a new Azure Migrate project
module "create_migrate_project" {
  source = "../../"

  location               = var.location
  name                   = "create-project"
  parent_id              = var.parent_id
  create_migrate_project = true # Set to true to create new project
  instance_type          = var.instance_type
  operation_mode         = "create-project"
  project_name           = var.project_name
  tags                   = var.tags
}
