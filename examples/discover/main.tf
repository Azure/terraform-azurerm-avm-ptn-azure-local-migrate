terraform {
  required_version = ">= 1.9"

  required_providers {
    azapi = {
      source  = "azure/azapi"
      version = "~> 2.4"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}

provider "azapi" {
  subscription_id = var.subscription_id
}

# Test Discovery
module "discover_vms" {
  source = "../.."

  location            = var.location
  name                = "migrate-discover"
  resource_group_name = var.resource_group_name
  instance_type       = var.instance_type
  operation_mode      = "discover"
  project_name        = var.project_name
  tags                = var.tags
}


