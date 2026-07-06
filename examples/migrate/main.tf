# Example: Migrate (Planned Failover) a Protected VM
# This example demonstrates how to perform a planned failover (migration) of a replicated VM to Azure Stack HCI
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

# Perform planned failover (migration) of a protected VM
module "migrate_vm" {
  source  = "Azure/avm-ptn-azure-local-migrate/azurerm"
  version = "0.1.3"

  name               = "vm-migration"
  parent_id          = var.parent_id
  operation_mode     = "migrate"
  protected_item_id  = var.target_object_id
  shutdown_source_vm = var.shutdown_source_vm
  tags               = var.tags
}
