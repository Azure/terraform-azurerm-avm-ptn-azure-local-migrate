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
# Example 1: Get Protected Item by ID
# ========================================

module "get_by_id" {
  source = "../.."

  location = "eastus"
  # Required variables
  name                = "migrate-get-by-id"
  resource_group_name = "saifaldinali-vmw-ga-bb-rg"
  instance_type       = "VMwareToAzStackHCI"
  # Operation mode
  operation_mode = "get"
  # Get by full resource ID
  protected_item_id = "/subscriptions/f6f66a94-f184-45da-ac12-ffbfd8a6eb29/resourceGroups/saifaldinali-vmw-ga-bb-rg/providers/Microsoft.DataReplication/replicationVaults/saifaldinaliVMWGABBreplicationvault/protectedItems/your-vm-name"
  # Tags
  tags = {
    Environment = "Test"
    Purpose     = "GetProtectedItem"
  }
}

# ========================================
# Example 2: Get Protected Item by Name
# ========================================

module "get_by_name" {
  source = "../.."

  location = "eastus"
  # Required variables
  name                = "migrate-get-by-name"
  resource_group_name = "saifaldinali-vmw-ga-bb-rg"
  instance_type       = "VMwareToAzStackHCI"
  # Operation mode
  operation_mode = "get"
  project_name   = "saifaldinali-vmw-ga-bb"
  # Get by name (requires project name to locate vault)
  protected_item_name = "your-vm-name"
  # Tags
  tags = {
    Environment = "Test"
    Purpose     = "GetProtectedItem"
  }
}

# ========================================
# Example 3: Get with Explicit Vault ID
# ========================================

module "get_with_vault" {
  source = "../.."

  location = "eastus"
  # Required variables
  name                = "migrate-get-with-vault"
  resource_group_name = "saifaldinali-vmw-ga-bb-rg"
  instance_type       = "VMwareToAzStackHCI"
  # Operation mode
  operation_mode = "get"
  # Get by name with explicit vault ID
  protected_item_name  = "your-vm-name"
  replication_vault_id = "/subscriptions/f6f66a94-f184-45da-ac12-ffbfd8a6eb29/resourceGroups/saifaldinali-vmw-ga-bb-rg/providers/Microsoft.DataReplication/replicationVaults/saifaldinaliVMWGABBreplicationvault"
  # Tags
  tags = {
    Environment = "Test"
    Purpose     = "GetProtectedItem"
  }
}

# ========================================
# OUTPUTS
# ========================================






