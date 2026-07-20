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

module "initialize_replication" {
  source  = "Azure/avm-ptn-azure-local-migrate/azurerm"
  version = "0.1.3"

  name                  = "local-migration-init"
  operation_mode        = "initialize"
  parent_id             = var.parent_id
  project_name          = var.project_name
  source_appliance_name = var.source_appliance_name
  target_appliance_name = var.target_appliance_name
}
