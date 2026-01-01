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
# Example 1: Migrate with Source VM Shutdown
# ========================================

module "migrate_with_shutdown" {
  source = "../.."

  location = "eastus"
  # Required variables
  name                = "migrate-vm-shutdown"
  resource_group_name = "saifaldinali-vmw-ga-bb-rg"
  instance_type       = "VMwareToAzStackHCI"
  # Operation mode
  operation_mode = "migrate"
  # Protected item to migrate
  protected_item_id = "/subscriptions/f6f66a94-f184-45da-ac12-ffbfd8a6eb29/resourceGroups/saifaldinali-vmw-ga-bb-rg/providers/Microsoft.DataReplication/replicationVaults/saifaldinaliVMWGABBreplicationvault/protectedItems/your-vm-name"
  # Shutdown source VM before migration (RECOMMENDED for data consistency)
  shutdown_source_vm = true
  # Tags
  tags = {
    Environment   = "Production"
    Purpose       = "Migration"
    MigrationType = "PlannedFailover"
  }
}

# ========================================
# Example 2: Migrate without Source VM Shutdown
# ========================================

module "migrate_without_shutdown" {
  source = "../.."

  location = "eastus"
  # Required variables
  name                = "migrate-vm-no-shutdown"
  resource_group_name = "saifaldinali-vmw-ga-bb-rg"
  instance_type       = "VMwareToAzStackHCI"
  # Operation mode
  operation_mode = "migrate"
  # Protected item to migrate
  protected_item_id = "/subscriptions/f6f66a94-f184-45da-ac12-ffbfd8a6eb29/resourceGroups/saifaldinali-vmw-ga-bb-rg/providers/Microsoft.DataReplication/replicationVaults/saifaldinaliVMWGABBreplicationvault/protectedItems/your-vm-name"
  # Do NOT shutdown source VM (less safe but faster)
  shutdown_source_vm = false
  # Tags
  tags = {
    Environment   = "Development"
    Purpose       = "Migration"
    MigrationType = "PlannedFailover"
  }
}

# ========================================
# OUTPUTS - Example 1
# ========================================






# ========================================
# OUTPUTS - Example 2
# ========================================


# ========================================
# DERIVED OUTPUTS - Pre-Migration Checks
# ========================================

