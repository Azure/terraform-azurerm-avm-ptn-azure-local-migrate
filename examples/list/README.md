# List Protected Items Example

This example demonstrates how to list all protected items (replicated VMs) in an Azure Migrate project using the "list" operation mode.

## Overview

The `list` operation retrieves all protected items (VMs being replicated) from a replication vault. This is useful for:
- Getting an overview of all replicating VMs
- Monitoring replication status across multiple VMs
- Identifying VMs with health issues
- Finding VMs ready for migration or test migration
- Generating reports on replication progress

## Usage Methods

### Method 1: List by Project Name (Recommended)

The module automatically discovers the vault from the project:

```hcl
module "list_replications" {
  source = "Azure/avm-res-migrate/azurerm"

  name                = "list-replications"
  location            = "eastus"
  resource_group_name = "your-rg"
  instance_type       = "VMwareToAzStackHCI"
  operation_mode      = "list"

  project_name = "migrate-project-001"

  tags = {
    Environment = "Production"
  }
}
```

### Method 2: List by Vault ID

If you already know the vault resource ID:

```hcl
module "list_replications" {
  source = "Azure/avm-res-migrate/azurerm"

  name                = "list-replications"
  location            = "eastus"
  resource_group_name = "your-rg"
  instance_type       = "VMwareToAzStackHCI"
  operation_mode      = "list"

  replication_vault_id = "/subscriptions/{sub-id}/resourceGroups/{rg}/providers/Microsoft.DataReplication/replicationVaults/{vault}"

  tags = {
    Environment = "Production"
  }
}
```

## Required Variables

| Variable | Description | Required |
|----------|-------------|----------|
| `name` | Name for the module instance | Yes |
| `location` | Azure region | Yes |
| `resource_group_name` | Resource group name | Yes |
| `instance_type` | Migration type (VMwareToAzStackHCI or HyperVToAzStackHCI) | Yes |
| `operation_mode` | Must be set to "list" | Yes |

## Conditional Variables

- **`project_name`** - Required if `replication_vault_id` is not provided
- **`replication_vault_id`** - Optional, overrides project-based vault lookup

## Outputs

### 1. Basic Listing Outputs

#### `protected_items_count`
Total number of protected items found.

```hcl
output "total_vms" {
  value = module.list_replications.protected_items_count
}
```

#### `protected_items_list`
Complete raw data for all protected items (full API response).

#### `protected_items_summary`
Formatted summary with key information for each item:

```hcl
output "summary" {
  value = module.list_replications.protected_items_summary
}
```

Returns array of objects with:
- `name` - Protected item name
- `id` - Full resource ID
- `protection_state` - Current replication state
- `protection_state_description` - Detailed state description
- `replication_health` - Health status (Normal, Warning, Critical, etc.)
- `source_machine_name` - Source VM name
- `target_vm_name` - Target VM name
- `target_resource_group_id` - Target resource group
- `policy_name` - Replication policy name
- `instance_type` - Migration type
- `allowed_jobs` - Operations currently allowed
- `health_errors_count` - Number of health errors
- `resynchronization_required` - Whether resync is needed

### 2. Grouped Outputs

#### `protected_items_by_state`
Items grouped by protection state:

```hcl
output "by_state" {
  value = module.list_replications.protected_items_by_state
}
```

Returns:
```json
{
  "Protected": ["vm1", "vm2"],
  "InitialReplicationInProgress": ["vm3"],
  "ProtectedStatesBegin": ["vm4"]
}
```

#### `protected_items_by_health`
Items grouped by replication health:

```hcl
output "by_health" {
  value = module.list_replications.protected_items_by_health
}
```

Returns:
```json
{
  "Normal": ["vm1", "vm2"],
  "Warning": ["vm3"],
  "Critical": ["vm4"]
}
```

#### `protected_items_with_errors`
Only items that have health errors:

```hcl
output "errors" {
  value = module.list_replications.protected_items_with_errors
}
```

Returns array with `name` and `health_errors` for each problematic item.

### 3. Derived Outputs (Examples)

You can create custom outputs based on the summary:

```hcl
# Count healthy items
output "healthy_count" {
  value = length([
    for item in module.list_replications.protected_items_summary :
    item.name if item.replication_health == "Normal"
  ])
}

# Items ready for test migration
output "ready_for_test" {
  value = [
    for item in module.list_replications.protected_items_summary :
    item.name if contains(item.allowed_jobs, "TestMigrate")
  ]
}

# Items ready for production migration
output "ready_for_migrate" {
  value = [
    for item in module.list_replications.protected_items_summary :
    item.name if contains(item.allowed_jobs, "Migrate")
  ]
}

# Items needing resynchronization
output "need_resync" {
  value = [
    for item in module.list_replications.protected_items_summary :
    item.name if item.resynchronization_required
  ]
}
```

## Example Output

```json
{
  "protected_items_count": 3,
  "protected_items_summary": [
    {
      "name": "web-server-01",
      "protection_state": "Protected",
      "replication_health": "Normal",
      "source_machine_name": "web-server-01",
      "target_vm_name": "web-server-01-migrated",
      "policy_name": "VMwareToAzStackHCIpolicy",
      "allowed_jobs": ["TestMigrate", "Migrate"],
      "health_errors_count": 0
    },
    {
      "name": "db-server-01",
      "protection_state": "InitialReplicationInProgress",
      "replication_health": "Normal",
      "source_machine_name": "db-server-01",
      "target_vm_name": "db-server-01-migrated",
      "policy_name": "VMwareToAzStackHCIpolicy",
      "allowed_jobs": ["DisableProtection"],
      "health_errors_count": 0
    }
  ]
}
```

## Common Use Cases

### 1. Dashboard/Monitoring
Get quick overview of replication status:

```hcl
output "replication_dashboard" {
  value = {
    total_vms     = module.list_replications.protected_items_count
    by_state      = module.list_replications.protected_items_by_state
    by_health     = module.list_replications.protected_items_by_health
    with_errors   = length(module.list_replications.protected_items_with_errors)
  }
}
```

### 2. Pre-Migration Readiness Check
Find VMs ready for migration:

```hcl
locals {
  ready_to_migrate = [
    for item in module.list_replications.protected_items_summary :
    item if contains(item.allowed_jobs, "Migrate") &&
            item.replication_health == "Normal" &&
            !item.resynchronization_required
  ]
}

output "migration_ready_vms" {
  value = [for item in local.ready_to_migrate : item.name]
}
```

### 3. Error Reporting
Generate report of problematic VMs:

```hcl
output "error_report" {
  value = {
    for item in module.list_replications.protected_items_with_errors :
    item.name => {
      error_count = length(item.health_errors)
      errors      = [for err in item.health_errors : err.message]
    }
  }
}
```

### 4. Filter by Source Machine
Find specific source machines:

```hcl
output "production_vms" {
  value = [
    for item in module.list_replications.protected_items_summary :
    item.name if can(regex("^prod-", item.source_machine_name))
  ]
}
```

## Running the Example

1. Update the subscription ID, resource group, and project name:
   ```bash
   # Edit main.tf with your values
   ```

2. Initialize Terraform:
   ```bash
   terraform init
   ```

3. Plan the operation:
   ```bash
   terraform plan
   ```

4. Apply to list the protected items:
   ```bash
   terraform apply
   ```

5. View the outputs:
   ```bash
   terraform output protected_items_summary
   terraform output items_by_health
   ```

## Notes

- The `list` operation is read-only and does not modify resources
- Requires at least Reader permissions on the replication vault
- Returns empty list if no protected items exist (not an error)
- Use `project_name` for automatic vault discovery
- Output includes pagination - all items are returned automatically
- Perfect for integration with monitoring/dashboard systems

## Python CLI Equivalent

```bash
# Terraform
operation_mode = "list"
project_name   = "my-project"

# Python CLI equivalent
az migrate local replication list \
  --resource-group my-rg \
  --project-name my-project
```
