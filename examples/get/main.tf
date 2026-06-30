# Example: Get Protected Item Details
# This example demonstrates how to retrieve details of a protected (replicating) VM
#

terraform {
  required_version = ">= 1.9"

  required_providers {
    azapi = {
      source  = "Azure/azapi"
      version = "~> 2.4"
    }
  }
}

provider "azapi" {}

# Get protected item details
module "get_protected_item" {
  source  = "Azure/avm-ptn-azure-local-migrate/azurerm"
  version = "0.1.2"

  name              = "get-protected-item"
  parent_id         = var.parent_id
  operation_mode    = "get"
  project_name      = var.project_name
  protected_item_id = var.protected_item_id
  tags              = var.tags
}






