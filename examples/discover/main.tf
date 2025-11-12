terraform {
  required_version = ">= 1.9"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    azapi = {
      source  = "azure/azapi"
      version = "~> 2.4"
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

  # Required variables
  name                 = "migrate-discover"
  location             = "eastus"  # Change to your region
  resource_group_name  = "saifaldinali-vmw-ga-bb-rg"
  instance_type        = "VMwareToAzStackHCI"  # or "HyperVToAzStackHCI"

  # Operation mode
  operation_mode = "discover"

  # Discovery Configuration
  project_name = "saifaldinali-vmw-ga-bb"

  # Optional: Specify appliance for targeted discovery
  # appliance_name      = "your-appliance-name"
  # source_machine_type = "VMware"  # or "HyperV"

  # Optional: Filter by display name
  # display_name = "web-server-01"

  # Tags
  tags = {
    Environment = "Test"
    Purpose     = "Discovery"
  }
}

# Output discovered servers
output "discovered_servers" {
  value = module.discover_vms.discovered_servers
}

output "discovered_servers_count" {
  value = module.discover_vms.discovered_servers_count
}
