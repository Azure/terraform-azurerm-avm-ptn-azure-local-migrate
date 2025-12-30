# Migrate (Planned Failover) Example

This example demonstrates how to perform a production migration (planned failover) of a replicated VM to Azure Stack HCI using the "migrate" operation mode.

## Overview

The `migrate` operation performs a **planned failover**, which is the production migration of a VM from the source environment (VMware/HyperV) to Azure Stack HCI. This is the final step in the migration process.

### What is Planned Failover?

Planned failover is a controlled migration that:
- Ensures data consistency by synchronizing all changes
- Optionally shuts down the source VM before migration
- Brings up the target VM on Azure Stack HCI
- Is the recommended method for production migrations

## ⚠️ IMPORTANT WARNINGS

**This operation will:**
1. **Migrate the VM to production** on Azure Stack HCI
2. **Optionally shut down the source VM** (if `shutdown_source_vm = true`)
3. **Start the target VM** on Azure Stack HCI
4. **Cannot be easily reversed** - this is a production cut-over

**Before running this operation:**
- ✅ Verify replication is complete and healthy
- ✅ Perform a test migration first (use test-migrate operation)
- ✅ Have a rollback plan
- ✅ Schedule during a maintenance window
- ✅ Notify stakeholders
- ✅ Backup critical data

## Prerequisites

1. **Replication must be established** - Use `replicate` operation first
2. **Initial replication must be complete** - VM must be in "Protected" state
3. **Replication health must be Normal** - No critical errors
4. **Test migration recommended** - Validate the migration works
5. **Arc Resource Bridge must be running** - On the target HCI cluster

## Usage

### Method 1: Migrate with Source VM Shutdown (RECOMMENDED)

**Best for:** Production migrations where data consistency is critical.

```hcl
module "migrate_vm" {
  source = "Azure/avm-res-migrate/azurerm"

  name                = "migrate-production-vm"
  location            = "eastus"
  resource_group_name = "migrate-rg"
  instance_type       = "VMwareToAzStackHCI"
  operation_mode      = "migrate"

  protected_item_id = "/subscriptions/{sub}/resourceGroups/{rg}/providers/Microsoft.DataReplication/replicationVaults/{vault}/protectedItems/{vm}"

  # RECOMMENDED: Shut down source VM before migration
  shutdown_source_vm = true

  tags = {
    Environment   = "Production"
    MigrationDate = "2025-01-15"
  }
}
```

### Method 2: Migrate without Source VM Shutdown

**Best for:** Development/test environments or when downtime is not acceptable.

⚠️ **Warning:** May result in data inconsistency if the source VM is actively being used.

```hcl
module "migrate_vm" {
  source = "Azure/avm-res-migrate/azurerm"

  name                = "migrate-dev-vm"
  location            = "eastus"
  resource_group_name = "migrate-rg"
  instance_type       = "VMwareToAzStackHCI"
  operation_mode      = "migrate"

  protected_item_id = "/subscriptions/{sub}/resourceGroups/{rg}/providers/Microsoft.DataReplication/replicationVaults/{vault}/protectedItems/{vm}"

  # Less safe: Don't shut down source VM
  shutdown_source_vm = false

  tags = {
    Environment = "Development"
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
| `operation_mode` | Must be set to "migrate" | Yes |
| `protected_item_id` | Full ARM resource ID of the protected item | Yes |
| `shutdown_source_vm` | Whether to shut down source VM (default: false) | No |

## Outputs

### `migration_status`
Summary of the migration operation:

```hcl
output "status" {
  value = module.migrate_vm.migration_status
}
```

Returns:
- `protected_item_id` - Item being migrated
- `shutdown_source_vm` - Whether source will be shut down
- `operation_status` - Status (Initiated)
- `message` - Success message
- `vm_name` - Name of the VM
- `source_machine_name` - Source VM name
- `target_vm_name` - Target VM name

### `migration_operation_details`
Complete API response including async operation URL for job tracking.

### `migration_protected_item_details`
Details of the protected item before migration:

```hcl
output "item_details" {
  value = module.migrate_vm.migration_protected_item_details
}
```

Returns:
- `name` - Protected item name
- `protection_state` - Current protection state
- `replication_health` - Health status
- `allowed_jobs` - Operations that can be performed
- `can_perform_migration` - Whether migration is allowed
- `source_machine_name` - Source VM name
- `target_vm_name` - Target VM name
- `target_resource_group_id` - Target resource group
- `target_hci_cluster_id` - Target HCI cluster

### `migration_validation_warnings`
Array of warnings or issues detected before migration:

```hcl
output "warnings" {
  value = module.migrate_vm.migration_validation_warnings
}
```

## Migration Workflow

### Complete Migration Process:

```hcl
# 1. Discover VMs
module "discover" {
  source = "../../"
  operation_mode = "discover"
  # ... other config
}

# 2. Initialize infrastructure
module "initialize" {
  source = "../../"
  operation_mode = "initialize"
  # ... other config
}

# 3. Start replication
module "replicate" {
  source = "../../"
  operation_mode = "replicate"
  # ... other config
}

# 4. Wait for replication to complete and test
# ... monitoring and test migration ...

# 5. Perform production migration
module "migrate" {
  source = "../../"
  operation_mode = "migrate"
  protected_item_id = module.replicate.protected_item_id
  shutdown_source_vm = true
  # ... other config
}
```

## Pre-Migration Validation

Use the outputs to validate readiness before migration:

```hcl
output "pre_migration_check" {
  value = {
    can_migrate = module.migrate.migration_protected_item_details.can_perform_migration
    health = module.migrate.migration_protected_item_details.replication_health
    warnings_count = length(module.migrate.migration_validation_warnings)
    is_ready = (
      module.migrate.migration_protected_item_details.can_perform_migration &&
      module.migrate.migration_protected_item_details.replication_health == "Normal" &&
      length(module.migrate.migration_validation_warnings) == 0
    )
  }
}
```

## Monitoring Migration Progress

After initiating migration, use the jobs operation to monitor:

```hcl
# Get the job details
module "check_migration_job" {
  source = "../../"
  operation_mode = "jobs"
  replication_vault_id = "{vault-id}"
  # ... other config
}

output "migration_jobs" {
  value = module.check_migration_job.replication_jobs_list
}
```

## Common Scenarios

### Scenario 1: Production Migration with Validation

```hcl
# Step 1: Validate VM is ready
module "check_readiness" {
  source = "../../"
  operation_mode = "get"
  protected_item_id = var.vm_to_migrate
  # ... config
}

# Step 2: Only migrate if ready
module "migrate" {
  source = "../../"
  operation_mode = "migrate"
  protected_item_id = var.vm_to_migrate
  shutdown_source_vm = true

  # Only run if VM is ready
  count = (
    module.check_readiness.protected_item_summary.replication_health == "Normal" &&
    contains(module.check_readiness.protected_item_summary.allowed_jobs, "PlannedFailover")
  ) ? 1 : 0
}
```

### Scenario 2: Batch Migration

```hcl
# List all VMs ready for migration
module "list_vms" {
  source = "../../"
  operation_mode = "list"
  project_name = "migrate-project"
  # ... config
}

locals {
  vms_ready_for_migration = [
    for vm in module.list_vms.protected_items_summary :
    vm.id if (
      contains(vm.allowed_jobs, "PlannedFailover") &&
      vm.replication_health == "Normal"
    )
  ]
}

# Migrate each VM (use with caution!)
module "migrate_vms" {
  for_each = toset(local.vms_ready_for_migration)

  source = "../../"
  operation_mode = "migrate"
  protected_item_id = each.value
  shutdown_source_vm = true
  # ... config
}
```

## Error Handling

The module will fail if:
- Protected item doesn't exist
- VM is not in a state that allows migration (e.g., still replicating)
- "PlannedFailover" is not in the allowed operations
- Network connectivity issues to Azure Stack HCI
- Arc Resource Bridge is not running (warning only)

Check the validation warnings output for issues:

```hcl
output "has_errors" {
  value = length(module.migrate.migration_validation_warnings) > 0
}

output "error_details" {
  value = [
    for warning in module.migrate.migration_validation_warnings :
    warning.message
  ]
}
```

## Best Practices

1. **Always test first** - Perform test migration before production
2. **Use shutdown** - Set `shutdown_source_vm = true` for production
3. **Schedule wisely** - Migrate during maintenance windows
4. **Validate health** - Check replication health is "Normal"
5. **Monitor progress** - Use the jobs operation to track migration
6. **Have rollback plan** - Know how to recover if migration fails
7. **Backup first** - Take backups of critical VMs
8. **Notify stakeholders** - Communication is key
9. **Document** - Keep records of what was migrated when
10. **Clean up** - Remove replication after successful migration

## Timeouts

The migration operation has generous timeouts:
- **Create**: 180 minutes (3 hours)
- **Update**: 180 minutes (3 hours)

Migrations can take significant time depending on VM size and network speed.

## Running the Example

1. **Prerequisites:**
   - VM must be replicating and in "Protected" state
   - Replication health must be "Normal"
   - Test migration recommended

2. **Update the configuration:**
   ```bash
   # Edit main.tf with your protected item ID
   ```

3. **Plan the migration:**
   ```bash
   terraform init
   terraform plan
   ```

4. **Review the plan carefully!** This will perform a production migration.

5. **Apply (during maintenance window):**
   ```bash
   terraform apply
   ```

6. **Monitor the migration:**
   ```bash
   # Use the jobs operation or Azure portal
   ```

## Python CLI Equivalent

```bash
# Terraform
operation_mode = "migrate"
protected_item_id = "/subscriptions/.../protectedItems/vm1"
shutdown_source_vm = true

# Python CLI equivalent
az migrate local start-migration \
  --protected-item-id "/subscriptions/.../protectedItems/vm1" \
  --turn-off-source-server true
```

## Notes

- **This is a production operation** - The VM will be migrated
- **Source VM shutdown is recommended** - Ensures data consistency
- **Operation is asynchronous** - Use jobs to track progress
- **Cannot be easily undone** - This is a one-way migration
- **Arc Resource Bridge must be running** - Required for successful migration
- **Network connectivity required** - Between source and target
- **Requires appropriate permissions** - Contributor or higher on resources
