# Example: List Protected Items
# This example demonstrates how to list all protected (replicating) VMs in a vault
#

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

# List all protected items in the vault
module "list_protected_items" {
  source = "../../"

  location       = var.location
  name           = "list-protected-items"
  parent_id      = var.parent_id
  instance_type  = var.instance_type
  operation_mode = "list"
  # List by project name (vault auto-discovered)
  project_name = var.project_name
  tags         = var.tags
}

