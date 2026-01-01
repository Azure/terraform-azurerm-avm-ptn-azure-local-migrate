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

# ========================================
# Example 1: List All Protected Items by Project
# ========================================

module "list_by_project" {
  source = "../.."

  location = "eastus"
  # Required variables
  name                = "migrate-list"
  resource_group_name = "saifaldinali-vmw-ga-bb-rg"
  instance_type       = "VMwareToAzStackHCI"
  # Operation mode
  operation_mode = "list"
  # List by project name (vault will be auto-discovered)
  project_name = "saifaldinali-vmw-ga-bb"
  # Tags
  tags = {
    Environment = "Test"
    Purpose     = "ListProtectedItems"
  }
}

# ========================================
# Example 2: List Protected Items by Vault ID
# ========================================

module "list_by_vault" {
  source = "../.."

  location = "eastus"
  # Required variables
  name                = "migrate-list-vault"
  resource_group_name = "saifaldinali-vmw-ga-bb-rg"
  instance_type       = "VMwareToAzStackHCI"
  # Operation mode
  operation_mode = "list"
  # List by explicit vault ID
  replication_vault_id = "/subscriptions/f6f66a94-f184-45da-ac12-ffbfd8a6eb29/resourceGroups/saifaldinali-vmw-ga-bb-rg/providers/Microsoft.DataReplication/replicationVaults/saifaldinaliVMWGABBreplicationvault"
  # Tags
  tags = {
    Environment = "Test"
    Purpose     = "ListProtectedItems"
  }
}

# ========================================
# OUTPUTS - Example 1
# ========================================






# ========================================
# OUTPUTS - Example 2
# ========================================



# ========================================
# DERIVED OUTPUTS - Useful Statistics
# ========================================





