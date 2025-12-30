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
# Example 1: List All Protected Items by Project
# ========================================

module "list_by_project" {
  source = "../.."

  # Required variables
  name                = "migrate-list"
  location            = "eastus"
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

  # Required variables
  name                = "migrate-list-vault"
  location            = "eastus"
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

output "total_protected_items" {
  description = "Total number of replicated VMs"
  value       = module.list_by_project.protected_items_count
}

output "protected_items_summary" {
  description = "Summary of all protected items"
  value       = module.list_by_project.protected_items_summary
}

output "items_by_state" {
  description = "Protected items grouped by protection state"
  value       = module.list_by_project.protected_items_by_state
}

output "items_by_health" {
  description = "Protected items grouped by replication health"
  value       = module.list_by_project.protected_items_by_health
}

output "items_with_errors" {
  description = "Protected items that have health errors"
  value       = module.list_by_project.protected_items_with_errors
}

# ========================================
# OUTPUTS - Example 2
# ========================================

output "vault_protected_items_count" {
  description = "Number of protected items in vault"
  value       = module.list_by_vault.protected_items_count
}

output "vault_protected_items_names" {
  description = "Names of all protected items in vault"
  value       = [for item in module.list_by_vault.protected_items_summary : item.name]
}

# ========================================
# DERIVED OUTPUTS - Useful Statistics
# ========================================

output "healthy_items_count" {
  description = "Count of items with Normal health"
  value = length([
    for item in module.list_by_project.protected_items_summary :
    item.name if item.replication_health == "Normal"
  ])
}

output "items_needing_attention_count" {
  description = "Count of items with health errors"
  value = length([
    for item in module.list_by_project.protected_items_summary :
    item.name if item.health_errors_count > 0
  ])
}

output "items_ready_for_test_migrate" {
  description = "Items that can perform test migration"
  value = [
    for item in module.list_by_project.protected_items_summary :
    item.name if contains(item.allowed_jobs, "TestMigrate")
  ]
}

output "items_ready_for_migrate" {
  description = "Items that can perform migration"
  value = [
    for item in module.list_by_project.protected_items_summary :
    item.name if contains(item.allowed_jobs, "Migrate")
  ]
}

output "items_requiring_resync" {
  description = "Items that require resynchronization"
  value = [
    for item in module.list_by_project.protected_items_summary :
    item.name if item.resynchronization_required
  ]
}
