# Remove Replication Example

This example demonstrates how to stop replication for migrated servers using the `remove` operation mode, which is equivalent to the Azure CLI Python command `az migrate local replication remove`.

## Overview

The remove operation stops replication for a protected server in Azure Migrate. This is typically used when:
- Migration is complete and you want to clean up replication resources
- You need to reconfigure replication with different settings
- You want to stop protecting a server
- Troubleshooting requires removing and recreating replication

## Python CLI Equivalent

This Terraform module provides the same functionality as:
```bash
az migrate local replication remove \
  --target-object-id "/subscriptions/.../protectedItems/vm-name" \
  --resource-group "rg-name" \
  --project-name "project-name"
```

## Features

- **Normal Removal**: Standard replication removal with cleanup
- **Force Removal**: Force delete when normal removal fails
- **Validation**: Checks if protected item exists and can be removed
- **Job Tracking**: Returns operation headers for tracking removal job
- **Error Handling**: Validates protection state before removal

## Usage Examples

### Example 1: Basic Removal

Remove replication for a single server:

```hcl
module "remove_replication" {
  source = "Azure/avm-res-migrate/azurerm"

  name                = "migration-remove"
  location            = "eastus"
  resource_group_name = "rg-migration"

  operation_mode   = "remove"
  target_object_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-migration/providers/Microsoft.DataReplication/replicationVaults/vault-migration/protectedItems/vm-web-server"
  force_remove     = false
}

output "status" {
  value = module.remove_replication.removal_status
}
```

### Example 2: Force Removal

Force remove when normal removal fails:

```hcl
module "force_remove" {
  source = "Azure/avm-res-migrate/azurerm"

  name                = "migration-force-remove"
  location            = "eastus"
  resource_group_name = "rg-migration"

  operation_mode   = "remove"
  target_object_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-migration/providers/Microsoft.DataReplication/replicationVaults/vault-migration/protectedItems/vm-stuck-server"
  force_remove     = true  # Use with caution!
}
```

### Example 3: Remove with Job Tracking

Remove replication and track the job status:

```hcl
# Step 1: Remove replication
module "remove_replication" {
  source = "Azure/avm-res-migrate/azurerm"

  name                = "migration-remove"
  location            = "eastus"
  resource_group_name = "rg-migration"

  operation_mode   = "remove"
  target_object_id = "/subscriptions/.../protectedItems/vm-app-server"
  force_remove     = false
}

# Step 2: Extract job name from response
locals {
  operation_location = try(
    module.remove_replication.removal_operation_headers.Azure-AsyncOperation,
    module.remove_replication.removal_operation_headers.Location
  )

  job_name = local.operation_location != null ? (
    length(regexall("/jobs/([^?/]+)", local.operation_location)) > 0 ?
    regexall("/jobs/([^?/]+)", local.operation_location)[0][0] : null
  ) : null
}

# Step 3: Track the job
module "track_job" {
  source = "Azure/avm-res-migrate/azurerm"
  count  = local.job_name != null ? 1 : 0

  name                = "migration-track"
  location            = "eastus"
  resource_group_name = "rg-migration"

  operation_mode = "jobs"
  project_name   = "migration-project"
  job_name       = local.job_name

  depends_on = [module.remove_replication]
}

output "job_status" {
  value = length(module.track_job) > 0 ? module.track_job[0].replication_job : null
}
```

## Output Format

### Removal Status Output

```json
{
  "protected_item_id": "/subscriptions/.../protectedItems/vm-web-server",
  "force_remove": false,
  "operation_status": "Initiated",
  "message": "Successfully initiated removal of replication for protected item '/subscriptions/.../protectedItems/vm-web-server'"
}
```

### Protected Item Details Output

```json
{
  "name": "vm-web-server",
  "protection_state": "Protected",
  "allowed_jobs": [
    "DisableProtection",
    "TestFailover",
    "PlannedFailover"
  ],
  "can_disable_protection": true,
  "replication_health": "Normal"
}
```

### Operation Headers Output

Contains response headers from the removal operation, including:
- `Azure-AsyncOperation`: URL to track the async operation
- `Location`: Alternative URL for job tracking
- `Retry-After`: Suggested polling interval in seconds

## Variables

### Required Variables

| Name | Type | Description |
|------|------|-------------|
| `operation_mode` | string | Must be set to `"remove"` |
| `target_object_id` | string | Protected item ARM ID to remove |

### Optional Variables

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `force_remove` | bool | `false` | Force delete the protected item |

## Protected Item ID Format

The `target_object_id` must be a valid protected item ARM ID:

```
/subscriptions/{subscription-id}/resourceGroups/{resource-group}/providers/Microsoft.DataReplication/replicationVaults/{vault-name}/protectedItems/{item-name}
```

You can obtain this ID from:
- Output of the `replicate` operation mode
- Azure Portal (Azure Migrate > Replicating machines)
- Azure CLI: `az migrate local replication list`

## When to Use Force Remove

Use `force_remove = true` **only** when:

- Normal removal fails with an error
- Protected item is stuck in a transitional state
- You need to clean up orphaned resources
- Migration has failed and cleanup is required

⚠️ **Warning**: Force removal may:
- Leave resources in an inconsistent state
- Skip cleanup operations
- Require manual cleanup of related resources
- Not wait for graceful shutdown

## Validation

Before removal, the module validates:

1. **Protected Item Exists**: Verifies the item ID is valid
2. **Can Disable Protection**: Checks if "DisableProtection" is in allowed jobs
3. **Protection State**: Ensures the item is in a removable state

If validation fails, Terraform will report an error before attempting removal.

## Removal States

The protected item must be in one of these states to be removed:

| State | Description | Can Remove |
|-------|-------------|------------|
| Protected | Actively replicating | ✅ Yes |
| ProtectedWithError | Replication with errors | ✅ Yes |
| ProtectionSuspended | Replication paused | ✅ Yes |
| UnprotectedValid | Not currently protected | ✅ Yes |
| FailedOverCommitted | Post-migration cleanup | ✅ Yes |
| InitialReplicationInProgress | Initial sync | ⚠️ With force |
| TestFailoverInProgress | Test in progress | ❌ No |

## Common Use Cases

### 1. Clean Up After Successful Migration

```hcl
# After failover and verification, remove replication
module "cleanup" {
  source = "Azure/avm-res-migrate/azurerm"

  name                = "cleanup-migration"
  location            = "eastus"
  resource_group_name = "rg-migration"

  operation_mode   = "remove"
  target_object_id = var.migrated_server_id
  force_remove     = false
}
```

### 2. Bulk Removal

```hcl
# Remove multiple protected items
locals {
  servers_to_remove = [
    "/subscriptions/.../protectedItems/vm-web-01",
    "/subscriptions/.../protectedItems/vm-web-02",
    "/subscriptions/.../protectedItems/vm-app-01"
  ]
}

module "bulk_remove" {
  source   = "Azure/avm-res-migrate/azurerm"
  for_each = toset(local.servers_to_remove)

  name                = "remove-${basename(each.key)}"
  location            = "eastus"
  resource_group_name = "rg-migration"

  operation_mode   = "remove"
  target_object_id = each.key
  force_remove     = false
}
```

### 3. Conditional Removal

```hcl
# Remove only if migration is successful
locals {
  should_cleanup = var.migration_status == "succeeded"
}

module "conditional_remove" {
  source = "Azure/avm-res-migrate/azurerm"
  count  = local.should_cleanup ? 1 : 0

  name                = "conditional-cleanup"
  location            = "eastus"
  resource_group_name = "rg-migration"

  operation_mode   = "remove"
  target_object_id = var.protected_item_id
  force_remove     = false
}
```

## Troubleshooting

### Error: Protected item not found

**Cause**: The `target_object_id` is invalid or the item doesn't exist.

**Solution**: Verify the ID format and existence:
```hcl
# List all protected items first
module "list_items" {
  operation_mode = "discover"
  # ... find the correct ID
}
```

### Error: Cannot remove in current state

**Cause**: The protected item has ongoing operations or is in a state that doesn't allow removal.

**Solution**:
1. Check the current state with jobs mode
2. Wait for ongoing operations to complete
3. Use `force_remove = true` if necessary

### Error: DisableProtection not in allowed jobs

**Cause**: The item is in a state that doesn't support removal (e.g., test failover in progress).

**Solution**:
1. Complete or cancel the ongoing operation
2. Wait for the item to return to a stable state
3. Retry the removal

## Requirements

- Protected item must exist in the vault
- Protected item must allow "DisableProtection" operation
- Appropriate permissions on the subscription and vault
- No blocking operations in progress (unless using force_remove)

## Related Commands

- **replicate**: Create replication for servers
- **jobs**: Track removal job status
- **discover**: Find protected items to remove

## Best Practices

1. **Always validate first**: Check protected item details before removal
2. **Track the job**: Use job tracking to monitor removal progress
3. **Avoid force remove**: Use only when absolutely necessary
4. **Clean up in order**: Remove test resources before production
5. **Document removals**: Track which items were removed and why
6. **Verify completion**: Check job status to ensure removal succeeded

## Next Steps

After removing replication:
1. Verify the removal job completed successfully
2. Check that related resources are cleaned up
3. Update your infrastructure-as-code to remove references
4. Document the removal for audit purposes
