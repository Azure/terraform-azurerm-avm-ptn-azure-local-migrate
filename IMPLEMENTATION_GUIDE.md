# Terraform Implementation of Azure Stack HCI Migration Commands

## Overview

This Terraform module provides Infrastructure as Code (IaC) equivalents for the Azure CLI Python implementation of Azure Stack HCI migration. It supports three main operations:

1. **Discover Servers** - Query discovered VMs from Azure Migrate
2. **Initialize Replication Infrastructure** - Set up replication components
3. **Create VM Replication** - Initiate VM migration to Azure Stack HCI

## Module Structure

```
terraform-azurerm-avm-res-migrate/
├── main.tf                      # Core resource definitions
├── variables.tf                 # Input variables for all commands
├── outputs-migration.tf         # Migration-specific outputs
├── locals.tf                    # Helper logic and transformations
├── examples/
│   ├── discover/main.tf        # Discovery command example
│   ├── initialize/main.tf      # Infrastructure setup example
│   └── replicate/main.tf       # VM replication example
└── MIGRATION_EXAMPLES.md        # Usage documentation
```

## Key Features

### 1. Discover Servers
- Query discovered servers from VMware or HyperV sites
- Filter by appliance name, display name, or machine name
- Output comprehensive server details (OS, IPs, disks, NICs)
- Process and categorize servers (Windows/Linux)

### 2. Initialize Replication Infrastructure
- Create/configure replication vault with managed identity
- Set up replication policy with customizable retention
- Create cache storage account automatically
- Configure replication extension between fabrics
- Assign RBAC roles (Contributor, Storage Blob Data Contributor)

### 3. Create VM Replication
- Two modes: Power User (full control) and Default User (simplified)
- Configure target VM sizing (CPU, RAM, dynamic memory)
- Select specific disks and NICs to replicate
- Specify target storage paths and networks
- Support for both VMware and HyperV sources

## Terraform vs Python CLI Comparison

### Discovery Command

**Python CLI:**
```python
def get_discovered_server(cmd, project_name, resource_group_name,
                          appliance_name=None, source_machine_type=None):
    # Query API and return discovered servers
```

**Terraform Equivalent:**
```hcl
module "discover" {
  source = "Azure/avm-res-migrate/azurerm"

  operation_mode      = "discover"
  resource_group_name = "rg-migrate"
  project_name        = "my-project"
  appliance_name      = "vmware-appliance"
  source_machine_type = "VMware"
}

output "servers" {
  value = module.discover.discovered_servers
}
```

### Initialize Infrastructure Command

**Python CLI:**
```python
def initialize_replication_infrastructure(cmd, resource_group_name,
                                         project_name,
                                         source_appliance_name,
                                         target_appliance_name):
    # Create vault, policy, storage, extension
```

**Terraform Equivalent:**
```hcl
module "initialize" {
  source = "Azure/avm-res-migrate/azurerm"

  operation_mode        = "initialize"
  resource_group_name   = "rg-migrate"
  project_name          = "my-project"
  source_appliance_name = "source-app"
  target_appliance_name = "target-app"
  source_fabric_id      = "<fabric-id>"
  target_fabric_id      = "<fabric-id>"
}
```

### Create Replication Command

**Python CLI:**
```python
def new_local_server_replication(cmd, target_storage_path_id,
                                 target_resource_group_id,
                                 target_vm_name,
                                 machine_id=None):
    # Create protected item for VM replication
```

**Terraform Equivalent:**
```hcl
module "replicate" {
  source = "Azure/avm-res-migrate/azurerm"

  operation_mode           = "replicate"
  resource_group_name      = "rg-migrate"
  machine_id               = "/subscriptions/.../machines/vm-01"
  target_vm_name           = "migrated-vm"
  target_storage_path_id   = "/subscriptions/.../storagecontainers/storage"
  target_resource_group_id = "/subscriptions/.../resourceGroups/rg-vms"

  # From initialize step
  replication_vault_id       = module.initialize.replication_vault_id
  replication_extension_name = module.initialize.replication_extension_name

  # Disk and NIC configuration
  disks_to_include = [...]
  nics_to_include  = [...]
}
```

## Advantages of Terraform Implementation

### 1. **Declarative State Management**
- Terraform tracks resource state automatically
- Easy to see what will change before applying
- Rollback capabilities through state management

### 2. **Reusability**
- Define once, use multiple times
- Variables and outputs for flexible configurations
- Module composition for complex scenarios

### 3. **Version Control**
- Infrastructure as Code in Git
- Peer review through pull requests
- Audit trail of all changes

### 4. **Idempotency**
- Safe to run multiple times
- Only creates/updates what's needed
- Prevents duplicate resources

### 5. **Integration**
- Works with CI/CD pipelines
- Combine with other Terraform modules
- Use with Terraform Cloud/Enterprise

## Usage Patterns

### Pattern 1: Sequential Execution
```hcl
# Step 1: Discover
module "discover" {
  operation_mode = "discover"
  # ... config
}

# Step 2: Initialize (depends on discovery)
module "initialize" {
  operation_mode = "initialize"
  # ... config

  depends_on = [module.discover]
}

# Step 3: Replicate (depends on initialization)
module "replicate" {
  operation_mode = "replicate"
  # ... config

  replication_vault_id = module.initialize.replication_vault_id
  depends_on = [module.initialize]
}
```

### Pattern 2: Batch Migration
```hcl
# Discover all VMs
module "discover_all" {
  operation_mode = "discover"
  project_name   = "project"
}

# Replicate multiple VMs
module "replicate_vms" {
  for_each = { for vm in module.discover_all.discovered_servers : vm.name => vm }

  operation_mode = "replicate"
  machine_id     = each.value.id
  target_vm_name = "${each.value.name}-migrated"
  # ... rest of config
}
```

### Pattern 3: Conditional Execution
```hcl
variable "migration_phase" {
  type    = string
  default = "discover"  # or "initialize" or "replicate"
}

module "migration" {
  source = "Azure/avm-res-migrate/azurerm"

  operation_mode = var.migration_phase
  # ... config based on phase
}
```

## API Mapping

| Python Function | Terraform Resource | API Endpoint |
|----------------|-------------------|--------------|
| `get_discovered_server()` | `data.azapi_resource_list.discovered_servers` | `Microsoft.OffAzure/.../machines` |
| `initialize_replication_infrastructure()` | `azapi_resource.replication_policy`, `azurerm_storage_account.cache`, `azapi_resource.replication_extension` | `Microsoft.DataReplication/...` |
| `new_local_server_replication()` | `azapi_resource.protected_item` | `Microsoft.DataReplication/.../protectedItems` |

## Variable Reference

### Discovery Variables
- `operation_mode` = "discover"
- `project_name` - Azure Migrate project
- `appliance_name` - Source appliance (site)
- `source_machine_type` - "VMware" or "HyperV"
- `display_name` - Filter by display name

### Initialize Variables
- `operation_mode` = "initialize"
- `source_appliance_name` - Source appliance name
- `target_appliance_name` - Target appliance name
- `source_fabric_id` - Source fabric ARM ID
- `target_fabric_id` - Target fabric ARM ID
- `instance_type` - "VMwareToAzStackHCI" or "HyperVToAzStackHCI"
- `cache_storage_account_id` - Optional existing storage

### Replicate Variables
- `operation_mode` = "replicate"
- `machine_id` - Discovered machine ARM ID
- `target_vm_name` - Name for migrated VM
- `target_storage_path_id` - HCI storage container
- `target_resource_group_id` - Target resource group
- `disks_to_include` - List of disks (power user)
- `nics_to_include` - List of NICs (power user)
- `target_virtual_switch_id` - Network (default user)

## Output Reference

### Discovery Outputs
- `discovered_servers` - List of discovered VMs with details
- `discovered_servers_count` - Total count

### Initialize Outputs
- `replication_vault_id` - Vault ARM ID
- `replication_policy_id` - Policy ARM ID
- `cache_storage_account_id` - Storage account ID
- `replication_extension_name` - Extension name (needed for replication)

### Replicate Outputs
- `protected_item_id` - Replicated item ARM ID
- `replication_state` - Current replication health
- `target_vm_name_output` - Target VM name

## Best Practices

1. **Use Remote State**: Store Terraform state in Azure Storage
2. **Variable Files**: Use `.tfvars` files for different environments
3. **Module Versioning**: Pin module versions for production
4. **Sensitive Data**: Mark sensitive outputs appropriately
5. **Dependencies**: Use `depends_on` for explicit ordering
6. **Tags**: Always include environment, owner, and purpose tags

## Limitations

1. **Stateful Operations**: Some operations (like waiting for fabric health) are handled differently than Python
2. **Error Handling**: Terraform errors differ from Python CLI errors
3. **Polling**: Terraform uses resource lifecycle instead of explicit polling loops
4. **Custom Logic**: Complex Python logic may need external data sources

## Future Enhancements

- [ ] Add support for machine_index (select VM by index)
- [ ] Implement custom validation functions
- [ ] Add more example scenarios (batch, phased migration)
- [ ] Support for additional instance types
- [ ] Integration with Terraform Cloud

## Testing

Run examples to test:

```bash
# Test discovery
cd examples/discover && terraform init && terraform plan

# Test initialize
cd examples/initialize && terraform init && terraform plan

# Test replicate
cd examples/replicate && terraform init && terraform plan
```

## Support

For issues or questions:
- Review the examples in `examples/`
- Check Azure Migrate documentation
- Open an issue in the repository
- Consult Terraform AzAPI provider docs
