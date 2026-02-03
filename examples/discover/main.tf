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

# Test Discovery
module "discover_vms" {
  source = "../.."

  location       = var.location
  name           = "migrate-discover"
  parent_id      = var.parent_id
  instance_type  = var.instance_type
  operation_mode = "discover"
  project_name   = var.project_name
  tags           = var.tags
}


