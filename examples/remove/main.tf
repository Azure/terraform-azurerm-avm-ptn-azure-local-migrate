# Example: Remove VM Replication
# This example demonstrates how to remove/disable replication for a protected item
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

# Remove replication for a protected item
module "remove_replication" {
  source = "../../"

  location         = var.location
  name             = "remove-replication"
  parent_id        = var.parent_id
  force_remove     = var.force_remove
  operation_mode   = "remove"
  tags             = var.tags
  target_object_id = var.target_object_id
}
