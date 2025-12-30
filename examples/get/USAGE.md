# Get Protected Item Operation - Quick Reference

## Overview
The `get` operation mode retrieves detailed information about a protected item (replicated VM) in Azure Migrate.

## Equivalent Python CLI Command
```python
az migrate local replication get \
  --protected-item-id <resource-id>
  # OR
  --protected-item-name <name> \
  --resource-group <rg> \
  --project-name <project>
```

## Terraform Usage

### Method 1: Get by ID (Recommended)
```hcl
module "get_protected_item" {
  source = "../../"

  name                = "get-vm-status"
  location            = "eastus"
  resource_group_name = "migrate-rg"
  instance_type       = "VMwareToAzStackHCI"
  operation_mode      = "get"

  protected_item_id = "/subscriptions/{sub}/resourceGroups/{rg}/providers/Microsoft.DataReplication/replicationVaults/{vault}/protectedItems/{vm}"
}

output "vm_status" {
  value = module.get_protected_item.protected_item_summary
}
```

### Method 2: Get by Name
```hcl
module "get_protected_item" {
  source = "../../"

  name                = "get-vm-status"
  location            = "eastus"
  resource_group_name = "migrate-rg"
  instance_type       = "VMwareToAzStackHCI"
  operation_mode      = "get"

  protected_item_name = "web-server-01"
  project_name        = "my-migrate-project"
}
```

## Key Outputs

| Output | Description |
|--------|-------------|
| `protected_item` | Complete raw API response |
| `protected_item_summary` | Formatted summary with key fields |
| `protected_item_health_errors` | Array of health errors |
| `protected_item_custom_properties` | Fabric-specific details |

## Key Information Retrieved

- **Protection State**: Current replication status
- **Health Status**: Overall health of replication
- **Policy & Extension**: Configuration details
- **Failover History**: Test/planned/unplanned failover times
- **Allowed Operations**: What actions can be performed
- **Machine Details**: Source and target VM information
- **Disk Configuration**: Disks being replicated
- **Network Configuration**: NIC settings
- **Health Errors**: Any issues with detailed messages

## Common Use Cases

1. **Monitor Replication Progress**
   ```hcl
   output "replication_status" {
     value = module.get_protected_item.protected_item_summary.protection_state_description
   }
   ```

2. **Check Health**
   ```hcl
   output "is_healthy" {
     value = module.get_protected_item.protected_item_summary.replication_health == "Normal"
   }
   ```

3. **Get Allowed Operations**
   ```hcl
   output "can_test_migrate" {
     value = contains(
       module.get_protected_item.protected_item_summary.allowed_jobs,
       "TestMigrate"
     )
   }
   ```

4. **Check for Errors**
   ```hcl
   output "has_errors" {
     value = length(module.get_protected_item.protected_item_health_errors) > 0
   }
   ```

## Requirements

- The protected item must exist
- Minimum Reader permissions on the replication vault
- Valid Azure authentication

## Validation

The module will fail with a clear error if:
- Protected item ID format is invalid
- Protected item doesn't exist
- Missing required parameters (name without project/vault)
- Insufficient permissions

## Best Practices

1. Use `protected_item_id` for direct, fast lookups
2. Use `protected_item_name` with `project_name` when you don't have the full ID
3. Check `allowed_jobs` before attempting operations like test migrate or failover
4. Monitor `health_errors` for troubleshooting
5. Store sensitive IDs in variables or secret management systems
