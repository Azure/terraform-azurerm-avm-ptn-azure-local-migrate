# Tests

This directory contains comprehensive **unit tests** and **integration tests** for the Azure Migrate Terraform module.

## Overview

The test suite is written in Go using [Terratest](https://terratest.gruntwork.io/) and covers all eight main operations:

1. **Discover** - Testing machine discovery functionality
2. **Initialize** - Testing replication infrastructure setup
3. **Replicate** - Testing VM replication configuration
4. **Jobs** - Testing job listing and monitoring
5. **Get** - Testing single protected item retrieval
6. **List** - Testing protected items listing
7. **Remove** - Testing protected item removal/cleanup
8. **Migrate** - Testing production migration (planned failover)

## Test Types

### Unit Tests (Fast, No Azure Resources)
- **File**: `unit_test.go`
- **Purpose**: Validate Terraform configuration logic without creating real resources
- **Methods**: `terraform validate`, `terraform plan` (no apply)
- **Duration**: Seconds to minutes
- **Cost**: FREE - no Azure resources created
- **Requirements**: No Azure credentials needed (for most tests)

### Integration Tests (Slow, Creates Real Resources)
- **Files**: `discover_test.go`, `initialize_test.go`, `replicate_test.go`, `jobs_test.go`, `remove_test.go`, `migrate_test.go`, `integration_test.go`
- **Purpose**: Test actual Azure resource creation and operations
- **Methods**: `terraform apply` with real Azure resources
- **Duration**: 30 minutes to 3 hours (migrate tests can take longest)
- **Cost**: $$$ - Creates actual Azure resources
- **Requirements**: Valid Azure credentials and permissions

## Test Structure

```
tests/
├── unit_test.go           # Unit tests (validate/plan only, NO resource creation)
├── discover_test.go       # Integration tests for discover operation
├── initialize_test.go     # Integration tests for initialize operation
├── replicate_test.go      # Integration tests for replicate operation
├── jobs_test.go           # Integration tests for jobs operation
├── get_test.go            # Integration tests for get operation
├── list_test.go           # Integration tests for list operation
├── remove_test.go         # Integration tests for remove operation
├── migrate_test.go        # Integration tests for migrate operation
├── integration_test.go    # End-to-end workflow integration tests
├── test_helpers.go        # Common test utilities
├── go.mod                 # Go module dependencies
├── Makefile               # Convenient test commands
└── README.md              # This file
```

## Prerequisites

### For Unit Tests (No Azure Required)

- [Go](https://golang.org/dl/) 1.21 or later
- [Terraform](https://www.terraform.io/downloads.html) 1.5 or later

### For Integration Tests (Azure Required)

- [Go](https://golang.org/dl/) 1.21 or later
- [Terraform](https://www.terraform.io/downloads.html) 1.5 or later
- [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli) (for authentication)
- Valid Azure subscription with proper permissions

### Environment Variables (Integration Tests Only)

Set the following environment variables before running integration tests:

```bash
# Required for integration tests
export ARM_SUBSCRIPTION_ID="your-subscription-id"
export ARM_TENANT_ID="your-tenant-id"
export ARM_CLIENT_ID="your-client-id"
export ARM_CLIENT_SECRET="your-client-secret"

# Required for cross-subscription tests (initialize & replicate)
export ARM_HCI_SUBSCRIPTION_ID="your-hci-subscription-id"
```

### Azure Permissions (Integration Tests Only)

The service principal or user running the tests needs:

- **Contributor** role on both subscriptions
- Permissions to create and manage:
  - Resource Groups
  - Storage Accounts
  - Data Replication Vaults
  - Replication Policies
  - Protected Items

## Running Tests

### Install Dependencies

```bash
cd tests
go mod download
```

### Run Unit Tests Only (Fast, No Azure)

**Recommended for local development and CI pipelines**

```bash
# Run all unit tests (validate/plan only, no resource creation)
go test -v -timeout 5m -run "^TestModule|^TestDiscover.*Configuration|^TestInitialize.*Configuration|^TestReplicate.*Configuration|^TestVariable|^TestResource|^TestDisk|^TestNetwork"

# Or use the Makefile
make test-unit
```

These tests:
- ✅ Complete in seconds to minutes
- ✅ Don't create Azure resources (FREE)
- ✅ Don't require Azure credentials
- ✅ Validate Terraform syntax and configuration logic

### Run Integration Tests (Slow, Creates Azure Resources)

**⚠️ WARNING: These tests create REAL Azure resources and may incur costs!**

```bash
# Run all integration tests (full terraform apply with real resources)
go test -v -timeout 60m

# Or use the Makefile
make test-integration
```

These tests:
- ⏱️ Take 30-60 minutes to complete
- 💰 Create actual Azure resources ($$$ COSTS MONEY $$$)
- 🔐 Require valid Azure credentials (see Environment Variables above)
- ✅ Test actual resource creation and operations

### Run Specific Test Suites

```bash
# Unit tests - No Azure resources
go test -v -timeout 5m -run TestModuleValidation
go test -v -timeout 5m -run TestDiscoverModeConfiguration
go test -v -timeout 5m -run TestInitializeModeConfiguration
go test -v -timeout 5m -run TestReplicateModeConfiguration
go test -v -timeout 5m -run TestJobsModeConfiguration
go test -v -timeout 5m -run TestRemoveModeConfiguration
go test -v -timeout 5m -run TestMigrateModeConfiguration
go test -v -timeout 5m -run TestOperationModeValidation

# Integration tests - Creates Azure resources
go test -v -timeout 30m -run TestDiscoverCommand
go test -v -timeout 30m -run TestInitializeCommand
go test -v -timeout 30m -run TestReplicateCommand
go test -v -timeout 30m -run TestJobsListAll
go test -v -timeout 30m -run TestJobsGetSpecific

# WARNING: Remove tests delete protected items!
go test -v -timeout 30m -run TestRemoveReplicationNormal
go test -v -timeout 30m -run TestRemoveReplicationForce

# CRITICAL: Migrate tests perform ACTUAL production migrations!
go test -v -timeout 180m -run TestMigrateCommandWithShutdown
go test -v -timeout 180m -run TestMigrateCommandHyperV
go test -v -timeout 180m -run TestMigrateCommandVMware

# Full workflow tests
go test -v -timeout 60m -run TestIntegrationWorkflow
```

### Run Tests with Parallel Execution

```bash
# Unit tests (safe to parallelize)
go test -v -timeout 5m -parallel 4 -run "^TestModule"

# Integration tests (be careful with Azure quotas)
go test -v -timeout 60m -parallel 2 -run TestDiscover
```

## Test Coverage

### Unit Tests (`unit_test.go`)

**Mock-based validation tests that don't create resources:**

- ✅ `TestModuleValidation` - Terraform syntax validation
- ✅ `TestDiscoverModeConfiguration` - Discover mode config with mock values
- ✅ `TestInitializeModeConfiguration` - Initialize mode config with mock values
- ✅ `TestReplicateModeConfiguration` - Replicate mode config with mock values
- ✅ `TestJobsModeConfiguration` - Jobs mode config with mock values
- ✅ `TestRemoveModeConfiguration` - Remove mode config with mock values
- ✅ `TestVariableValidation` - Variable constraints and validation rules
- ✅ `TestResourceNaming` - Resource naming pattern validation
- ✅ `TestDiskConfiguration` - Disk configuration logic
- ✅ `TestNetworkConfiguration` - Network configuration logic
- ✅ `TestOperationModeValidation` - All operation modes validation

These tests use **mock values** like:
- `"mock-rg"` - Resource group names
- `"mock-project"` - Project names
- `"00000000-0000-0000-0000-000000000000"` - Mock GUIDs
- `"mock-vault"` - Vault names
- `"mock-job-123"` - Job names
- `"/subscriptions/.../protectedItems/mock-item"` - Protected item IDs
- Validate configuration structure without Azure API calls

### Discover Tests (`discover_test.go`)

**Integration tests that create real Azure resources:**

- ✅ `TestDiscoverCommand` - Basic discovery functionality
- ✅ `TestDiscoverCommandValidation` - Input validation
- ✅ `TestDiscoverCommandOutputFormats` - Output format validation
- Tests verify:
  - Discovered machines output structure
  - Machine properties and metadata
  - Filtered output fields
  - Discovery data consistency

### Initialize Tests (`initialize_test.go`)

**Integration tests that create real Azure resources:**

- ✅ `TestInitializeCommand` - Infrastructure creation
- ✅ `TestInitializeCommandResourceCreation` - All resources created
- ✅ `TestInitializeCommandIdempotency` - Idempotent operations
- ✅ `TestInitializeCommandNaming` - Resource naming conventions
- ✅ `TestInitializeCommandPolicyConfiguration` - Policy settings
- ✅ `TestInitializeCommandFabricTypes` - Different fabric types
- ✅ `TestInitializeCommandVaultCreation` - Vault creation scenarios
- Tests verify:
  - Replication vault creation
  - Storage account configuration
  - Replication policy setup
  - Source/target fabric configuration
  - DRA (replication agent) setup
  - Replication extension deployment
  - Cross-subscription configuration

### Replicate Tests (`replicate_test.go`)

**Integration tests that create real Azure resources:**

- ✅ `TestReplicateCommand` - Basic replication
- ✅ `TestReplicateCommandWithMultipleDisks` - Multi-disk VMs
- ✅ `TestReplicateCommandWithDynamicMemory` - Dynamic memory
- ✅ `TestReplicateCommandVMSizing` - Various VM sizes
- ✅ `TestReplicateCommandHyperVGeneration` - Gen1 and Gen2
- ✅ `TestReplicateCommandInstanceTypes` - VMware/HyperV to HCI
- ✅ `TestReplicateCommandNetworkConfiguration` - NIC setup
- ✅ `TestReplicateCommandValidation` - Input validation
- ✅ `TestReplicateCommandIdempotency` - Idempotent operations
- ✅ `TestReplicateCommandMachineNameUsage` - Machine name vs ID
- Tests verify:
  - Protected item creation
  - Replication state tracking
  - Target VM configuration
  - Disk configuration (OS and data disks)
  - Network adapter setup
  - VM sizing (CPU, RAM)
  - Hyper-V generation settings
  - Instance type configurations

### Jobs Tests (`jobs_test.go`)

**Integration tests that create real Azure resources:**

- ✅ `TestJobsListAll` - List all replication jobs in vault
- ✅ `TestJobsGetSpecific` - Retrieve specific job by name
- ✅ `TestJobsOutputStructure` - Validate output structure
- ✅ `TestJobsWithProjectName` - Job retrieval using project name
- ✅ `TestJobsWithVaultID` - Job retrieval using explicit vault ID
- ✅ `TestJobsErrorHandling` - Error cases (invalid job name)
- Tests verify:
  - Job list retrieval from vault
  - Specific job details retrieval
  - Job output structure (name, state, vm_name, errors, tasks)
  - Vault resolution from project name
  - Job tracking for migration operations

**Required Environment Variables for Jobs Tests:**
```bash
export ARM_SUBSCRIPTION_ID="..."
export ARM_RESOURCE_GROUP="..."
export ARM_PROJECT_NAME="..."          # For project-based vault lookup
export ARM_VAULT_ID="..."              # For explicit vault ID tests
export ARM_JOB_NAME="..."              # For specific job retrieval
```

### Remove Tests (`remove_test.go`)

**Integration tests that create real Azure resources (and DESTROY them):**

⚠️ **WARNING**: These tests **DELETE** protected items. Use with caution!

- ✅ `TestRemoveReplicationNormal` - Normal replication removal
- ✅ `TestRemoveReplicationForce` - Force replication removal
- ✅ `TestRemoveOutputStructure` - Validate output structure
- ✅ `TestRemoveValidation` - Protected item validation before removal
- ✅ `TestRemoveErrorHandling` - Error cases (invalid item ID)
- ✅ `TestRemoveWithJobTracking` - Removal with job tracking
- ✅ `TestRemoveProtectedItemValidation` - DisableProtection check
- ✅ `TestRemoveIdempotency` - Removal idempotency behavior
- Tests verify:
  - Protected item deletion
  - Force delete option
  - Pre-removal validation (protection state, allowed jobs)
  - Operation headers for job tracking
  - Error handling for non-existent items
  - Removal job initiation

**Required Environment Variables for Remove Tests:**
```bash
export ARM_SUBSCRIPTION_ID="..."
export ARM_RESOURCE_GROUP="..."
export ARM_PROTECTED_ITEM_ID="..."         # Item to remove (normal)
export ARM_PROTECTED_ITEM_ID_FORCE="..."   # Item to force remove
export ARM_PROTECTED_ITEM_ID_IDEMPOTENT="..." # Item for idempotency test
export ARM_PROJECT_NAME="..."              # For job tracking tests
```

### Migrate Tests (`migrate_test.go`)

**Integration tests that perform PRODUCTION migrations (planned failover):**

⚠️ **CRITICAL WARNING**: These tests perform **ACTUAL MIGRATIONS** to production. This is a **ONE-WAY OPERATION**!

- ✅ `TestMigrateCommandWithShutdown` - Migration with source VM shutdown (RECOMMENDED)
- ✅ `TestMigrateCommandWithoutShutdown` - Migration without shutdown (faster but riskier)
- ✅ `TestMigrateCommandHyperV` - HyperV to AzStackHCI migration
- ✅ `TestMigrateCommandVMware` - VMware to AzStackHCI migration
- ✅ `TestMigrateCommandValidation` - Pre-migration validation checks
- ✅ `TestMigrateCommandInvalidProtectedItem` - Error handling for invalid items
- ✅ `TestMigrateCommandOutputs` - Verify all migration outputs
- ✅ `TestMigrateCommandResourceID` - Protected item resource ID validation
- ✅ `TestMigrateCommandTimeout` - Migration timeout handling (up to 3 hours)
- ✅ `TestMigrateCommandInstanceTypeValidation` - Instance type validation
- ✅ `TestMigrateCommandIdempotency` - Migration idempotency behavior
- ✅ `TestMigrateCommandTags` - Tag application during migration
- ✅ `TestMigrateCommandParallelExecution` - Multiple parallel migrations

**Test Coverage:**
- Protected item validation before migration
- Planned failover operation initiation
- Source VM shutdown options (true/false)
- Both instance types (HyperVToAzStackHCI, VMwareToAzStackHCI)
- Operation tracking and async job monitoring
- Migration status, operation details, and validation warnings outputs
- Resource ID format validation
- Timeout configuration (180 minutes)
- Error handling for invalid/non-existent items
- Idempotency checks
- Tag propagation
- Parallel migration support

**Required Environment Variables for Migrate Tests:**
```bash
export ARM_SUBSCRIPTION_ID="..."
export ARM_RESOURCE_GROUP_NAME="..."
export ARM_PROTECTED_ITEM_ID="..."                  # Item to migrate with shutdown
export ARM_PROTECTED_ITEM_ID_NO_SHUTDOWN="..."      # Item to migrate without shutdown
export ARM_PROTECTED_ITEM_ID_HYPERV="..."           # HyperV item to migrate
export ARM_PROTECTED_ITEM_ID_VMWARE="..."           # VMware item to migrate
export ARM_PROTECTED_ITEM_ID_1="..."                # Item for parallel test 1
export ARM_PROTECTED_ITEM_ID_2="..."                # Item for parallel test 2
```

**Migration Operation Notes:**
- Migration is the **final step** in the workflow: discover → initialize → replicate → migrate
- This performs a **planned failover** (production migration) to Azure Stack HCI
- Once initiated, the operation **cannot be reversed** - source VM will be migrated to target
- Recommended to set `shutdown_source_vm = true` for data consistency
- Migration can take **up to 3 hours** depending on VM size and data
- After migration, the VM runs on Azure Stack HCI cluster
- Source VM on VMware/HyperV is shut down (if shutdown option enabled)
- Migration status can be tracked via async operation URL in outputs

⚠️ **IMPORTANT**: Remove tests will **permanently delete** protected items. Ensure you're using test resources that can be safely removed.

### Integration Tests (`integration_test.go`)

**End-to-end workflow tests that create real Azure resources:**

- ✅ `TestFullMigrationWorkflow` - Complete workflow (Discover → Initialize → Replicate)
- ✅ `TestWorkflowWithMultipleVMs` - Multiple VM replication
- ✅ `TestCrossSubscriptionMigration` - Cross-subscription scenarios
- ✅ `TestErrorHandlingAndRecovery` - Error scenarios
- ✅ `TestResourceCleanup` - Cleanup verification
- ✅ `TestPerformanceAndScaling` - Performance testing
- ✅ `TestDataConsistency` - State consistency
- Tests verify:
  - End-to-end migration workflow
  - Multi-VM scenarios
  - Cross-subscription operations
  - Error handling and recovery
  - Resource cleanup
  - Performance characteristics

## Test Patterns

### Unit Test Pattern (Mock Values, No Resources)

```go
func TestConfigurationValidation(t *testing.T) {
    t.Parallel()  // Safe to run in parallel (no real resources)

    terraformOptions := &terraform.Options{
        TerraformDir: "..",
        Vars: map[string]interface{}{
            // Use MOCK values - no real Azure resources
            "subscription_id": "00000000-0000-0000-0000-000000000000",
            "resource_group_name": "mock-rg",
            "project_name": "mock-project",
            "command": "discover",
        },
        NoColor: true,
    }

    // Validate syntax only (no apply, no resources created)
    err := terraform.ValidateE(t, terraformOptions)
    assert.NoError(t, err)

    // Or test plan (validates logic without creating resources)
    _, err = terraform.InitAndPlanE(t, terraformOptions)
    assert.NoError(t, err)
}
```

### Integration Test Pattern (Real Resources)

```go
func TestExampleFeature(t *testing.T) {
    t.Parallel()  // Run in parallel with other tests

    // Setup with REAL Azure credentials
    terraformOptions := &terraform.Options{
        TerraformDir: "../examples/discover",
        Vars: map[string]interface{}{
            "subscription_id": os.Getenv("ARM_SUBSCRIPTION_ID"),
        },
        NoColor: true,
    }

    // Cleanup REAL resources
    defer terraform.Destroy(t, terraformOptions)

    // Execute (creates REAL Azure resources, costs money!)
    terraform.InitAndApply(t, terraformOptions)

    // Verify
    output := terraform.Output(t, terraformOptions, "output_name")
    assert.NotEmpty(t, output)
}
```

### Validation Test Pattern

```go
func TestValidation(t *testing.T) {
    tests := []struct {
        name          string
        vars          map[string]interface{}
        expectedError bool
        description   string
    }{
        // Test cases
    }

    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            // Test logic
        })
    }
}
```

## Best Practices

### For Unit Tests (Mock-based)
1. **Use mock values** - Never use real subscription IDs or resource names
2. **Use terraform.ValidateE()** - Validate syntax without creating resources
3. **Use terraform.InitAndPlanE()** - Test logic without apply
4. **Run in parallel** - Safe since no real resources are created
5. **Fast feedback** - Keep tests under 5 minutes total
6. **No Azure credentials** - Should work without ARM_* environment variables

### For Integration Tests (Real resources)
1. **Use t.Parallel() carefully** - Consider Azure quotas and costs
2. **Clean up resources** - Always use `defer terraform.Destroy()` to clean up
3. **Skip when needed** - Skip tests when required environment variables are missing
4. **Use descriptive names** - Test names should clearly describe what they test
5. **Verify thoroughly** - Check both success cases and error handling
6. **Test idempotency** - Verify resources can be applied multiple times safely
7. **Use helper functions** - Leverage `test_helpers.go` for common operations
8. **Long timeouts** - Use `-timeout 60m` for integration tests

## When to Use Which Test Type

### Use Unit Tests (`unit_test.go`) for:
- ✅ CI/CD pipelines (fast feedback)
- ✅ Local development (quick validation)
- ✅ Syntax and structure validation
- ✅ Variable constraint testing
- ✅ Resource naming pattern checks
- ✅ Pull request checks (no cost)

### Use Integration Tests (other test files) for:
- ✅ Pre-release validation
- ✅ Actual Azure API interaction testing
- ✅ End-to-end workflow verification
- ✅ Cross-subscription scenarios
- ✅ Performance testing
- ✅ Real-world use case validation

## Troubleshooting

### Tests Timeout

If tests timeout, increase the timeout value:

```bash
# Unit tests (should be fast)
go test -v -timeout 5m -run "^TestModule"

# Integration tests (can be slow)
go test -v -timeout 60m -run TestDiscover
```

### Authentication Errors (Integration Tests)

Ensure Azure credentials are properly set:

```bash
az login
az account set --subscription "your-subscription-id"
```

### Resource Cleanup Issues (Integration Tests)

If resources aren't cleaned up after failed tests, manually delete them:

```bash
az group delete --name <test-resource-group> --yes --no-wait
```

### Parallel Test Conflicts

If parallel tests cause conflicts, reduce parallelism:

```bash
go test -v -parallel 1
```

## CI/CD Integration

### GitHub Actions Example

```yaml
name: Terratest

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Setup Go
        uses: actions/setup-go@v4
        with:
          go-version: '1.21'

      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v2
        with:
          terraform_version: '1.5.0'

      - name: Run Tests
        env:
          ARM_SUBSCRIPTION_ID: ${{ secrets.ARM_SUBSCRIPTION_ID }}
          ARM_TENANT_ID: ${{ secrets.ARM_TENANT_ID }}
          ARM_CLIENT_ID: ${{ secrets.ARM_CLIENT_ID }}
          ARM_CLIENT_SECRET: ${{ secrets.ARM_CLIENT_SECRET }}
        run: |
          cd tests
          go test -v -timeout 45m
```

## Contributing

When adding new tests:

1. Follow existing test patterns
2. Add tests for both success and failure cases
3. Update this README with new test descriptions
4. Ensure tests are idempotent and clean up resources
5. Add appropriate assertions using `testify/assert`

## Additional Resources

- [Terratest Documentation](https://terratest.gruntwork.io/)
- [Azure Migrate Documentation](https://docs.microsoft.com/en-us/azure/migrate/)
- [Terraform Testing Best Practices](https://www.terraform.io/docs/extend/testing/)
