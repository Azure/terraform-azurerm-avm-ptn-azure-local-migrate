# Example: Migrate (Planned Failover) a Protected VM
# This example demonstrates how to perform a planned failover (migration) of a replicated VM to Azure Stack HCI
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

# Perform planned failover (migration) of a protected VM
module "migrate_vm" {
  source = "../../"

  location           = var.location
  name               = "vm-migration"
  parent_id          = var.parent_id
  instance_type      = var.instance_type
  operation_mode     = "migrate"
  protected_item_id  = var.protected_item_id
  shutdown_source_vm = var.shutdown_source_vm
  tags               = var.tags
}
