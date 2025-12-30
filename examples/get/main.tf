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

# ========================================
# Example 1: Get Protected Item by ID
# ========================================

module "get_by_id" {
  source = "../.."

  # Required variables
  name                = "migrate-get-by-id"
  location            = "eastus"
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

  # Required variables
  name                = "migrate-get-by-name"
  location            = "eastus"
  resource_group_name = "saifaldinali-vmw-ga-bb-rg"
  instance_type       = "VMwareToAzStackHCI"

  # Operation mode
  operation_mode = "get"

  # Get by name (requires project name to locate vault)
  protected_item_name = "your-vm-name"
  project_name        = "saifaldinali-vmw-ga-bb"

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

  # Required variables
  name                = "migrate-get-with-vault"
  location            = "eastus"
  resource_group_name = "saifaldinali-vmw-ga-bb-rg"
  instance_type       = "VMwareToAzStackHCI"

  # Operation mode
  operation_mode = "get"

  # Get by name with explicit vault ID
  protected_item_name   = "your-vm-name"
  replication_vault_id  = "/subscriptions/f6f66a94-f184-45da-ac12-ffbfd8a6eb29/resourceGroups/saifaldinali-vmw-ga-bb-rg/providers/Microsoft.DataReplication/replicationVaults/saifaldinaliVMWGABBreplicationvault"

  # Tags
  tags = {
    Environment = "Test"
    Purpose     = "GetProtectedItem"
  }
}

# ========================================
# OUTPUTS
# ========================================

# Example 1 outputs
output "protected_item_by_id_summary" {
  description = "Summary of protected item retrieved by ID"
  value       = module.get_by_id.protected_item_summary
}

output "protected_item_by_id_health" {
  description = "Health errors for protected item retrieved by ID"
  value       = module.get_by_id.protected_item_health_errors
}

# Example 2 outputs
output "protected_item_by_name_summary" {
  description = "Summary of protected item retrieved by name"
  value       = module.get_by_name.protected_item_summary
}

output "protected_item_by_name_full" {
  description = "Full details of protected item retrieved by name"
  value       = module.get_by_name.protected_item
}

# Example 3 outputs
output "protected_item_with_vault_custom_properties" {
  description = "Custom properties of protected item"
  value       = module.get_with_vault.protected_item_custom_properties
}

output "protected_item_with_vault_allowed_operations" {
  description = "Allowed operations on protected item"
  value       = try(module.get_with_vault.protected_item_summary.allowed_jobs, [])
}
