# List Protected Items Operation - Quick Reference

## Overview
The `list` operation mode retrieves all protected items (replicated VMs) from a replication vault in Azure Migrate.

## Equivalent Python CLI Command
```bash
az migrate local replication list \
  --resource-group <rg> \
  --project-name <project>
```

## Terraform Usage

### Method 1: List by Project (Recommended)
```hcl
module "list_replications" {
  source = "../../"

  name                = "list-vms"
  location            = "eastus"
  resource_group_name = "migrate-rg"
  instance_type       = "VMwareToAzStackHCI"
  operation_mode      = "list"

  project_name = "my-migrate-project"
}

output "all_vms" {
  value = module.list_replications.protected_items_summary
}

output "total_count" {
  value = module.list_replications.protected_items_count
}
```

### Method 2: List by Vault ID
```hcl
module "list_replications" {
  source = "../../"

  name                = "list-vms"
  location            = "eastus"
  resource_group_name = "migrate-rg"
  instance_type       = "VMwareToAzStackHCI"
  operation_mode      = "list"

  replication_vault_id = "/subscriptions/{sub}/resourceGroups/{rg}/providers/Microsoft.DataReplication/replicationVaults/{vault}"
}
```

## Key Outputs

| Output | Description |
|--------|-------------|
| `protected_items_count` | Total number of protected items |
| `protected_items_list` | Complete raw API response |
| `protected_items_summary` | Formatted summary with key fields |
| `protected_items_by_state` | Items grouped by protection state |
| `protected_items_by_health` | Items grouped by replication health |
| `protected_items_with_errors` | Only items that have errors |

## Summary Output Structure

Each item in `protected_items_summary` contains:

```hcl
{
  name                         = "vm-name"
  id                           = "/subscriptions/.../protectedItems/vm-name"
  protection_state             = "Protected"
  protection_state_description = "The VM is protected"
  replication_health           = "Normal"
  source_machine_name          = "source-vm-01"
  target_vm_name               = "target-vm-01"
  target_resource_group_id     = "/subscriptions/.../resourceGroups/target-rg"
  policy_name                  = "VMwareToAzStackHCIpolicy"
  replication_extension_name   = "replication-extension"
  instance_type                = "VMwareToAzStackHCI"
  allowed_jobs                 = ["TestMigrate", "Migrate"]
  health_errors_count          = 0
  resynchronization_required   = false
}
```

## Common Queries

### 1. Count Healthy VMs
```hcl
output "healthy_count" {
  value = length([
    for item in module.list_replications.protected_items_summary :
    item if item.replication_health == "Normal"
  ])
}
```

### 2. Find VMs Ready for Test Migration
```hcl
output "ready_for_test" {
  value = [
    for item in module.list_replications.protected_items_summary :
    item.name if contains(item.allowed_jobs, "TestMigrate")
  ]
}
```

### 3. Find VMs Ready for Production Migration
```hcl
output "ready_for_migrate" {
  value = [
    for item in module.list_replications.protected_items_summary :
    item.name if contains(item.allowed_jobs, "Migrate")
  ]
}
```

### 4. Find VMs with Errors
```hcl
output "vms_with_errors" {
  value = [
    for item in module.list_replications.protected_items_summary :
    item.name if item.health_errors_count > 0
  ]
}
```

### 5. Find VMs Needing Resync
```hcl
output "need_resync" {
  value = [
    for item in module.list_replications.protected_items_summary :
    item.name if item.resynchronization_required
  ]
}
```

### 6. Group by Protection State
```hcl
output "by_state" {
  value = module.list_replications.protected_items_by_state
}
# Returns: { "Protected": ["vm1", "vm2"], "InitialReplicationInProgress": ["vm3"] }
```

### 7. Filter by Source Machine Name Pattern
```hcl
output "production_vms" {
  value = [
    for item in module.list_replications.protected_items_summary :
    item if can(regex("^prod-", item.source_machine_name))
  ]
}
```

### 8. Get Migration Readiness Status
```hcl
locals {
  migration_ready = [
    for item in module.list_replications.protected_items_summary :
    item if (
      contains(item.allowed_jobs, "Migrate") &&
      item.replication_health == "Normal" &&
      !item.resynchronization_required &&
      item.health_errors_count == 0
    )
  ]
}

output "migration_ready_count" {
  value = length(local.migration_ready)
}

output "migration_ready_vms" {
  value = [for item in local.migration_ready : item.name]
}
```

## Dashboard Example

Create a comprehensive dashboard output:

```hcl
output "replication_dashboard" {
  value = {
    # Summary
    total_vms           = module.list_replications.protected_items_count
    healthy_vms         = length([for i in module.list_replications.protected_items_summary : i if i.replication_health == "Normal"])
    vms_with_errors     = length(module.list_replications.protected_items_with_errors)

    # By State
    by_state            = module.list_replications.protected_items_by_state

    # By Health
    by_health           = module.list_replications.protected_items_by_health

    # Readiness
    ready_for_test      = length([for i in module.list_replications.protected_items_summary : i if contains(i.allowed_jobs, "TestMigrate")])
    ready_for_migrate   = length([for i in module.list_replications.protected_items_summary : i if contains(i.allowed_jobs, "Migrate")])
    need_resync         = length([for i in module.list_replications.protected_items_summary : i if i.resynchronization_required])
  }
}
```

## Requirements

- The project/vault must exist
- At least Reader permissions on the replication vault
- Valid Azure authentication

## Notes

- Returns empty list if no protected items exist (not an error)
- Read-only operation - no resources modified
- Includes automatic pagination - all items returned
- Perfect for monitoring and reporting
- Use with Terraform Cloud/Enterprise for automated reporting

## Best Practices

1. Use `project_name` for simplicity - automatic vault discovery
2. Store outputs in Terraform state for tracking changes over time
3. Use with remote state for team collaboration
4. Create custom outputs for specific reporting needs
5. Combine with other operations (get, jobs) for detailed monitoring
6. Schedule regular runs for continuous monitoring
