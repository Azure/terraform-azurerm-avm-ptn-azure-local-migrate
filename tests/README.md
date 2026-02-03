# Tests

This directory contains **unit tests** for the Azure Migrate Terraform module using Terraform's native testing framework.

## Overview

The test suite validates all operation modes and variable configurations:

1. **Discover** - Testing machine discovery operation mode
2. **Initialize** - Testing replication infrastructure setup mode
3. **Replicate** - Testing VM replication configuration mode
4. **Jobs** - Testing job listing and monitoring mode
5. **Get** - Testing single protected item retrieval mode
6. **List** - Testing protected items listing mode
7. **Remove** - Testing protected item removal/cleanup mode
8. **Migrate** - Testing production migration (planned failover) mode
9. **Create-Project** - Testing Azure Migrate project creation mode

## Test Types

### Unit Tests (Fast, No Azure Resources)

- **Location**: `tests/unit/`
- **File**: `unit.tftest.hcl`
- **Purpose**: Validate Terraform configuration logic without creating real resources
- **Methods**: `terraform plan` with mock providers
- **Duration**: Seconds
- **Cost**: FREE - no Azure resources created
- **Requirements**: No Azure credentials needed

## Running Tests

### Prerequisites

- Terraform >= 1.9.0 (for native test support)
- No Azure credentials required for unit tests

### Run All Unit Tests

```bash
# From the module root directory
terraform test -test-directory=tests/unit
```

### Run with Verbose Output

```bash
terraform test -test-directory=tests/unit -verbose
```

## Test Coverage

### Operation Mode Tests

Each operation mode is tested to ensure:
- The mode is correctly identified via `var.operation_mode`
- The corresponding local flag (e.g., `local.is_discover_mode`) is set to `true`
- Required variables for each mode are validated

| Mode | Test Name | Required Variables |
|------|-----------|-------------------|
| discover | `valid_operation_mode_discover` | `project_name` |
| initialize | `valid_operation_mode_initialize` | `project_name`, `location`, `cache_storage_account_id` |
| replicate | `valid_operation_mode_replicate` | `project_name` |
| jobs | `valid_operation_mode_jobs` | `replication_vault_id` |
| remove | `valid_operation_mode_remove` | `target_object_id` |
| get | `valid_operation_mode_get` | `protected_item_id` |
| list | `valid_operation_mode_list` | `replication_vault_id` |
| migrate | `valid_operation_mode_migrate` | `protected_item_id` |
| create-project | `valid_operation_mode_create_project` | `project_name` |

### Variable Validation Tests

Tests that verify variable validation rules work correctly:

- `invalid_operation_mode` - Rejects invalid operation modes
- `invalid_hyperv_generation` - Rejects invalid Hyper-V generations (must be "1" or "2")
- `invalid_instance_type` - Rejects invalid instance types
- `invalid_source_machine_type` - Rejects invalid source machine types
- `invalid_subscription_id_format` - Rejects malformed subscription GUIDs
- `invalid_name_too_short` - Rejects names that don't meet length requirements
- `invalid_lock_kind` - Rejects invalid lock kinds

### Default Value Tests

Tests that verify default values are set correctly:

- `default_values_check` - Validates boolean defaults (create_resource_group, force_remove, etc.)
- `default_replication_policy_values` - Validates replication timing defaults
- `default_vm_values` - Validates VM configuration defaults (CPU cores, RAM, disk size)

### Fabric Instance Type Tests

Tests that verify fabric type mappings:

- `target_fabric_instance_type_always_azstackhci` - Target is always AzStackHCI
- VMware source maps to `VMwareMigrate` fabric type
- HyperV source maps to `HyperVMigrate` fabric type

## Mock Provider Configuration

Unit tests use Terraform's `mock_provider` feature to simulate Azure API responses without actual Azure connectivity. The mock configuration includes:

- `azapi` - Mocked data sources and resources with sample ARM IDs
- `modtm` - Mocked telemetry provider
- `random` - Mocked random provider
- `time` - Mocked time provider

## Adding New Tests

To add new tests:

1. Edit `tests/unit/unit.tftest.hcl`
2. Add a new `run` block with the test name
3. Set `command = plan` for validation tests
4. Use `variables {}` block to override default test values
5. Add `assert {}` blocks for success conditions
6. Use `expect_failures = [var.variable_name]` for validation error tests

### Example Test

```hcl
run "my_new_test" {
  command = plan

  variables {
    operation_mode = "discover"
    my_variable    = "test_value"
  }

  assert {
    condition     = var.my_variable == "test_value"
    error_message = "Variable should be set to test_value"
  }
}
```

## Integration Testing

For integration tests that create real Azure resources, use the example configurations in the `/examples` directory with manual `terraform apply` commands or CI/CD pipelines with appropriate Azure credentials.

## Troubleshooting

### Common Issues

1. **Mock provider errors**: Ensure all required data source attributes are provided in mock defaults
2. **Validation failures**: Check that test variables meet all validation rules
3. **Missing variables**: Some operation modes require specific variables to be set

### Debug Mode

Run tests with increased verbosity:

```bash
TF_LOG=DEBUG terraform test -test-directory=tests/unit
```
