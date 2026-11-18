# Example: Migrate (Planned Failover) a Protected VM
# This example demonstrates how to perform a planned failover (migration) of a replicated VM to Azure Stack HCI
#

terraform {
  required_version = ">= 1.12.0, < 2.0"

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
  source = "../../"

  location           = var.location
  name               = "vm-migration"
  parent_id          = var.parent_id
  enable_telemetry   = var.enable_telemetry
  operation_mode     = "migrate"
  protected_item_id  = var.target_object_id
  shutdown_source_vm = var.shutdown_source_vm
  tags               = var.tags
}
