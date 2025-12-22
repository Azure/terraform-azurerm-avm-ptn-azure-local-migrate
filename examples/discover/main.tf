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
  subscription_id = "f6f66a94-f184-45da-ac12-ffbfd8a6eb29"
}

provider "azapi" {
  subscription_id = "f6f66a94-f184-45da-ac12-ffbfd8a6eb29"
}

# Test Discovery
module "discover_vms" {
  source = "../.."

  location = "eastus" # Change to your region
  # Required variables
  name                = "migrate-discover"
  resource_group_name = "saifaldinali-vmw-ga-bb-rg"
  instance_type       = "VMwareToAzStackHCI" # or "HyperVToAzStackHCI"
  # Operation mode
  operation_mode = "discover"
  # Discovery Configuration
  project_name = "saifaldinali-vmw-ga-bb"
  # Tags
  tags = {
    Environment = "Test"
    Purpose     = "Discovery"
  }
}


