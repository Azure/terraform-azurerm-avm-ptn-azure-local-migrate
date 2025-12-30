# Get Protected Item Example

This example demonstrates how to retrieve details about a protected item (replicated VM) using the Azure Migrate module in "get" mode.

## Overview

The `get` operation mode allows you to retrieve detailed information about a protected item, including:
- Protection state and health status
- Replication configuration (policy, extension)
- Failover history
- Allowed operations
- Machine details (source and target)
- Disk and network configuration
- Health errors and warnings

## Usage Methods

### Method 1: Get by Resource ID (Preferred)

Use this method when you have the full ARM resource ID of the protected item:

```hcl
module "get_by_id" {
  source = "Azure/avm-res-migrate/azurerm"

  name                = "migrate-get"
  location            = "eastus"
  resource_group_name = "your-rg"
  instance_type       = "VMwareToAzStackHCI"
  operation_mode      = "get"

  protected_item_id = "/subscriptions/{sub-id}/resourceGroups/{rg}/providers/Microsoft.DataReplication/replicationVaults/{vault}/protectedItems/{vm-name}"

  tags = {
    Environment = "Production"
  }
}
```

### Method 2: Get by Name with Project

Use this method when you know the protected item name and the Migrate project:

```hcl
module "get_by_name" {
  source = "Azure/avm-res-migrate/azurerm"

  name                = "migrate-get"
  location            = "eastus"
  resource_group_name = "your-rg"
  instance_type       = "VMwareToAzStackHCI"
  operation_mode      = "get"

  protected_item_name = "web-server-01"
  project_name        = "migrate-project-001"

  tags = {
    Environment = "Production"
  }
}
```

### Method 3: Get by Name with Vault ID

Use this method when you know the protected item name and replication vault ID:

```hcl
module "get_with_vault" {
  source = "Azure/avm-res-migrate/azurerm"

  name                = "migrate-get"
  location            = "eastus"
  resource_group_name = "your-rg"
  instance_type       = "VMwareToAzStackHCI"
  operation_mode      = "get"

  protected_item_name  = "web-server-01"
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
| `operation_mode` | Must be set to "get" | Yes |

## Conditional Variables

### For Method 1 (By ID):
- `protected_item_id` - Full ARM resource ID of the protected item

### For Method 2 (By Name + Project):
- `protected_item_name` - Name of the protected item
- `project_name` - Name of the Azure Migrate project

### For Method 3 (By Name + Vault):
- `protected_item_name` - Name of the protected item
- `replication_vault_id` - Full ARM resource ID of the replication vault

## Outputs

### Summary Output
```hcl
output "summary" {
  value = module.get_by_id.protected_item_summary
}
```

Returns:
- `id` - Resource ID
- `name` - Protected item name
- `protection_state` - Current protection state
- `replication_health` - Health status
- `policy_name` - Associated replication policy
- `allowed_jobs` - List of allowed operations
- `source_machine_name` - Source VM name
- `target_vm_name` - Target VM name
- `last_test_failover_time` - Last test failover timestamp
- And more...

### Full Details Output
```hcl
output "full_details" {
  value = module.get_by_id.protected_item
}
```

Returns the complete API response with all properties.

### Health Errors Output
```hcl
output "health_errors" {
  value = module.get_by_id.protected_item_health_errors
}
```

Returns array of health errors with error codes, messages, and recommended actions.

### Custom Properties Output
```hcl
output "custom_properties" {
  value = module.get_by_id.protected_item_custom_properties
}
```

Returns fabric-specific details including disk configuration, network settings, and more.

## Example Output Values

```json
{
  "protected_item_summary": {
    "id": "/subscriptions/.../protectedItems/web-server-01",
    "name": "web-server-01",
    "protection_state": "ProtectedStatesBegin",
    "protection_state_description": "Initial Replication in Progress",
    "replication_health": "Normal",
    "policy_name": "VMwareToAzStackHCIpolicy",
    "allowed_jobs": ["TestMigrate", "CancelTestMigrate"],
    "source_machine_name": "web-server-01",
    "target_vm_name": "web-server-01-migrated",
    "instance_type": "VMwareToAzStackHCI"
  }
}
```

## Common Use Cases

1. **Check Replication Status**: Monitor the current state of VM replication
2. **Verify Health**: Check for errors or warnings
3. **Plan Operations**: See which operations (test migrate, migrate, etc.) are currently allowed
4. **Audit Configuration**: Review replication settings and target configuration
5. **Troubleshooting**: Get detailed error information for failed replications

## Running the Example

1. Update the subscription ID, resource group, and project name in `main.tf`
2. Update the `protected_item_id` or `protected_item_name` with your VM details
3. Initialize Terraform:
   ```bash
   terraform init
   ```
4. Plan the operation:
   ```bash
   terraform plan
   ```
5. Apply to retrieve the information:
   ```bash
   terraform apply
   ```

The output will display the protected item details in the Terraform outputs.

## Notes

- The `get` operation is read-only and does not modify any resources
- You must have at least Reader permissions on the replication vault
- The protected item must exist; the module will fail if it's not found
- Use `protected_item_id` for the most direct lookup (fastest)
- Use `protected_item_name` with `project_name` when you don't have the full resource ID
