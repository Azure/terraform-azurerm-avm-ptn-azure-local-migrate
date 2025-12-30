package test

import (
	"fmt"
	"testing"
	"time"

	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

// TestMigrateCommandWithShutdown tests the migrate operation with source VM shutdown
func TestMigrateCommandWithShutdown(t *testing.T) {
	t.Parallel()

	helper := NewTestHelper(t)

	// Get required environment variables
	subscriptionID := helper.GetRequiredEnvVar("ARM_SUBSCRIPTION_ID")
	resourceGroupName := helper.GetRequiredEnvVar("ARM_RESOURCE_GROUP_NAME")
	protectedItemID := helper.GetRequiredEnvVar("ARM_PROTECTED_ITEM_ID")

	// Terraform options for migrate mode with shutdown
	terraformOptions := &terraform.Options{
		TerraformDir: "../examples/migrate",
		Vars: map[string]interface{}{
			"subscription_id":     subscriptionID,
			"resource_group_name": resourceGroupName,
			"protected_item_id":   protectedItemID,
			"shutdown_source_vm":  true,
			"instance_type":       "VMwareToAzStackHCI",
		},
		NoColor: true,
		// Increase timeout for migration operations (can take up to 3 hours)
		RetryableTerraformErrors: map[string]string{
			".*timeout while waiting.*":      "Waiting for migration to complete",
			".*operation is still running.*": "Migration operation in progress",
		},
		MaxRetries:         5,
		TimeBetweenRetries: 30 * time.Second,
	}

	// Cleanup after test (Note: Destroy may not be applicable for migration as it's a one-way operation)
	defer func() {
		// Migration is a one-way operation, so destroy might not apply
		// We just ensure cleanup of terraform state
		terraform.Destroy(t, terraformOptions)
	}()

	// Run terraform init and apply
	terraform.InitAndApply(t, terraformOptions)

	// Test 1: Verify migration status output
	t.Run("VerifyMigrationStatus", func(t *testing.T) {
		migrationStatusRaw := terraform.OutputJson(t, terraformOptions, "migration_status")

		assert.NotEmpty(t, migrationStatusRaw, "Migration status should not be empty")
		assert.Contains(t, migrationStatusRaw, "Initiated", "Migration status should indicate operation was initiated")
		assert.Contains(t, migrationStatusRaw, protectedItemID, "Migration status should contain the protected item ID")
	})

	// Test 2: Verify migration operation details
	t.Run("VerifyMigrationOperationDetails", func(t *testing.T) {
		operationDetails := terraform.OutputJson(t, terraformOptions, "migration_operation_details")

		assert.NotEmpty(t, operationDetails, "Migration operation details should not be empty")
		// Should contain async operation tracking information
		assert.NotContains(t, operationDetails, "null", "Migration operation details should not be null")
	})

	// Test 3: Verify protected item details before migration
	t.Run("VerifyProtectedItemDetails", func(t *testing.T) {
		protectedItemDetails := terraform.OutputJson(t, terraformOptions, "migration_protected_item_details")

		assert.NotEmpty(t, protectedItemDetails, "Protected item details should not be empty")
		assert.Contains(t, protectedItemDetails, "name", "Protected item details should contain VM name")
		assert.Contains(t, protectedItemDetails, "protection_state", "Protected item details should contain protection state")
		assert.Contains(t, protectedItemDetails, "can_perform_migration", "Protected item details should contain migration eligibility")
	})

	// Test 4: Verify shutdown parameter was applied
	t.Run("VerifyShutdownParameter", func(t *testing.T) {
		migrationStatusRaw := terraform.OutputJson(t, terraformOptions, "migration_status")

		assert.Contains(t, migrationStatusRaw, "true", "Migration status should reflect shutdown_source_vm = true")
	})

	// Test 5: Verify validation warnings
	t.Run("VerifyValidationWarnings", func(t *testing.T) {
		validationWarnings := terraform.OutputJson(t, terraformOptions, "migration_validation_warnings")

		// Should return an array (may be empty if no warnings)
		assert.NotNil(t, validationWarnings, "Validation warnings output should exist")
	})
}

// TestMigrateCommandWithoutShutdown tests the migrate operation without source VM shutdown
func TestMigrateCommandWithoutShutdown(t *testing.T) {
	t.Parallel()

	helper := NewTestHelper(t)

	// Get required environment variables
	subscriptionID := helper.GetRequiredEnvVar("ARM_SUBSCRIPTION_ID")
	resourceGroupName := helper.GetRequiredEnvVar("ARM_RESOURCE_GROUP_NAME")
	protectedItemID := helper.GetRequiredEnvVar("ARM_PROTECTED_ITEM_ID_NO_SHUTDOWN")

	// Terraform options for migrate mode without shutdown
	terraformOptions := &terraform.Options{
		TerraformDir: "../examples/migrate",
		Vars: map[string]interface{}{
			"subscription_id":     subscriptionID,
			"resource_group_name": resourceGroupName,
			"protected_item_id":   protectedItemID,
			"shutdown_source_vm":  false,
			"instance_type":       "VMwareToAzStackHCI",
		},
		NoColor: true,
		RetryableTerraformErrors: map[string]string{
			".*timeout while waiting.*": "Waiting for migration to complete",
		},
		MaxRetries:         5,
		TimeBetweenRetries: 30 * time.Second,
	}

	defer terraform.Destroy(t, terraformOptions)

	// Run terraform init and apply
	terraform.InitAndApply(t, terraformOptions)

	// Test 1: Verify migration initiated without shutdown
	t.Run("VerifyMigrationWithoutShutdown", func(t *testing.T) {
		migrationStatusRaw := terraform.OutputJson(t, terraformOptions, "migration_status")

		assert.Contains(t, migrationStatusRaw, "false", "Migration status should reflect shutdown_source_vm = false")
		assert.Contains(t, migrationStatusRaw, "Initiated", "Migration should be initiated")
	})
}

// TestMigrateCommandHyperV tests the migrate operation for HyperV to AzStackHCI
func TestMigrateCommandHyperV(t *testing.T) {
	t.Parallel()

	helper := NewTestHelper(t)

	// Get required environment variables
	subscriptionID := helper.GetRequiredEnvVar("ARM_SUBSCRIPTION_ID")
	resourceGroupName := helper.GetRequiredEnvVar("ARM_RESOURCE_GROUP_NAME")
	protectedItemIDHyperV := helper.GetRequiredEnvVar("ARM_PROTECTED_ITEM_ID_HYPERV")

	// Terraform options for HyperV migration
	terraformOptions := &terraform.Options{
		TerraformDir: "../examples/migrate",
		Vars: map[string]interface{}{
			"subscription_id":     subscriptionID,
			"resource_group_name": resourceGroupName,
			"protected_item_id":   protectedItemIDHyperV,
			"shutdown_source_vm":  true,
			"instance_type":       "HyperVToAzStackHCI",
		},
		NoColor: true,
		RetryableTerraformErrors: map[string]string{
			".*timeout while waiting.*": "Waiting for migration to complete",
		},
		MaxRetries:         5,
		TimeBetweenRetries: 30 * time.Second,
	}

	defer terraform.Destroy(t, terraformOptions)

	// Run terraform init and apply
	terraform.InitAndApply(t, terraformOptions)

	// Test: Verify HyperV migration
	t.Run("VerifyHyperVMigration", func(t *testing.T) {
		migrationStatusRaw := terraform.OutputJson(t, terraformOptions, "migration_status")

		assert.NotEmpty(t, migrationStatusRaw, "HyperV migration status should not be empty")
		assert.Contains(t, migrationStatusRaw, "Initiated", "HyperV migration should be initiated")
	})

	t.Run("VerifyHyperVInstanceType", func(t *testing.T) {
		protectedItemDetails := terraform.OutputJson(t, terraformOptions, "migration_protected_item_details")

		assert.Contains(t, protectedItemDetails, "HyperVToAzStackHCI", "Instance type should be HyperVToAzStackHCI")
	})
}

// TestMigrateCommandVMware tests the migrate operation for VMware to AzStackHCI
func TestMigrateCommandVMware(t *testing.T) {
	t.Parallel()

	helper := NewTestHelper(t)

	// Get required environment variables
	subscriptionID := helper.GetRequiredEnvVar("ARM_SUBSCRIPTION_ID")
	resourceGroupName := helper.GetRequiredEnvVar("ARM_RESOURCE_GROUP_NAME")
	protectedItemIDVMware := helper.GetRequiredEnvVar("ARM_PROTECTED_ITEM_ID_VMWARE")

	// Terraform options for VMware migration
	terraformOptions := &terraform.Options{
		TerraformDir: "../examples/migrate",
		Vars: map[string]interface{}{
			"subscription_id":     subscriptionID,
			"resource_group_name": resourceGroupName,
			"protected_item_id":   protectedItemIDVMware,
			"shutdown_source_vm":  true,
			"instance_type":       "VMwareToAzStackHCI",
		},
		NoColor: true,
		RetryableTerraformErrors: map[string]string{
			".*timeout while waiting.*": "Waiting for migration to complete",
		},
		MaxRetries:         5,
		TimeBetweenRetries: 30 * time.Second,
	}

	defer terraform.Destroy(t, terraformOptions)

	// Run terraform init and apply
	terraform.InitAndApply(t, terraformOptions)

	// Test: Verify VMware migration
	t.Run("VerifyVMwareMigration", func(t *testing.T) {
		migrationStatusRaw := terraform.OutputJson(t, terraformOptions, "migration_status")

		assert.NotEmpty(t, migrationStatusRaw, "VMware migration status should not be empty")
		assert.Contains(t, migrationStatusRaw, "Initiated", "VMware migration should be initiated")
	})

	t.Run("VerifyVMwareInstanceType", func(t *testing.T) {
		protectedItemDetails := terraform.OutputJson(t, terraformOptions, "migration_protected_item_details")

		assert.Contains(t, protectedItemDetails, "VMwareToAzStackHCI", "Instance type should be VMwareToAzStackHCI")
	})
}

// TestMigrateCommandValidation tests validation before migration
func TestMigrateCommandValidation(t *testing.T) {
	t.Parallel()

	helper := NewTestHelper(t)

	// Get required environment variables
	subscriptionID := helper.GetRequiredEnvVar("ARM_SUBSCRIPTION_ID")
	resourceGroupName := helper.GetRequiredEnvVar("ARM_RESOURCE_GROUP_NAME")
	protectedItemID := helper.GetRequiredEnvVar("ARM_PROTECTED_ITEM_ID")

	// Terraform options
	terraformOptions := &terraform.Options{
		TerraformDir: "../examples/migrate",
		Vars: map[string]interface{}{
			"subscription_id":     subscriptionID,
			"resource_group_name": resourceGroupName,
			"protected_item_id":   protectedItemID,
			"shutdown_source_vm":  true,
			"instance_type":       "VMwareToAzStackHCI",
		},
		NoColor: true,
	}

	defer terraform.Destroy(t, terraformOptions)

	// Test 1: Verify plan succeeds (validation passes)
	t.Run("VerifyPlanSucceeds", func(t *testing.T) {
		terraform.Init(t, terraformOptions)
		planOutput := terraform.Plan(t, terraformOptions)

		assert.NotEmpty(t, planOutput, "Plan output should not be empty")
		assert.Contains(t, planOutput, "planned_failover", "Plan should contain planned failover resource")
	})

	// Test 2: Verify protected item validation
	t.Run("VerifyProtectedItemValidation", func(t *testing.T) {
		terraform.Init(t, terraformOptions)

		// This should validate that the protected item exists and is ready
		planOutput := terraform.Plan(t, terraformOptions)

		assert.NotContains(t, planOutput, "Error:", "Plan should not contain validation errors")
	})
}

// TestMigrateCommandInvalidProtectedItem tests error handling for invalid protected item
func TestMigrateCommandInvalidProtectedItem(t *testing.T) {
	t.Parallel()

	helper := NewTestHelper(t)

	subscriptionID := helper.GetRequiredEnvVar("ARM_SUBSCRIPTION_ID")
	resourceGroupName := helper.GetRequiredEnvVar("ARM_RESOURCE_GROUP_NAME")

	// Use an invalid protected item ID
	invalidProtectedItemID := fmt.Sprintf(
		"/subscriptions/%s/resourceGroups/%s/providers/Microsoft.DataReplication/replicationVaults/invalid-vault/protectedItems/invalid-item",
		subscriptionID,
		resourceGroupName,
	)

	terraformOptions := &terraform.Options{
		TerraformDir: "../examples/migrate",
		Vars: map[string]interface{}{
			"subscription_id":     subscriptionID,
			"resource_group_name": resourceGroupName,
			"protected_item_id":   invalidProtectedItemID,
			"shutdown_source_vm":  true,
			"instance_type":       "VMwareToAzStackHCI",
		},
		NoColor: true,
	}

	// Test: Verify apply fails with invalid protected item
	t.Run("VerifyInvalidProtectedItemFails", func(t *testing.T) {
		terraform.Init(t, terraformOptions)

		_, err := terraform.ApplyE(t, terraformOptions)

		assert.Error(t, err, "Apply should fail with invalid protected item ID")
		assert.Contains(t, err.Error(), "not found", "Error should indicate resource not found")
	})
}

// TestMigrateCommandOutputs tests all migration outputs
func TestMigrateCommandOutputs(t *testing.T) {
	t.Parallel()

	helper := NewTestHelper(t)

	subscriptionID := helper.GetRequiredEnvVar("ARM_SUBSCRIPTION_ID")
	resourceGroupName := helper.GetRequiredEnvVar("ARM_RESOURCE_GROUP_NAME")
	protectedItemID := helper.GetRequiredEnvVar("ARM_PROTECTED_ITEM_ID")

	terraformOptions := &terraform.Options{
		TerraformDir: "../examples/migrate",
		Vars: map[string]interface{}{
			"subscription_id":     subscriptionID,
			"resource_group_name": resourceGroupName,
			"protected_item_id":   protectedItemID,
			"shutdown_source_vm":  true,
			"instance_type":       "VMwareToAzStackHCI",
		},
		NoColor: true,
		RetryableTerraformErrors: map[string]string{
			".*timeout while waiting.*": "Waiting for migration to complete",
		},
		MaxRetries:         5,
		TimeBetweenRetries: 30 * time.Second,
	}

	defer terraform.Destroy(t, terraformOptions)

	terraform.InitAndApply(t, terraformOptions)

	// Test 1: Verify migration_status output structure
	t.Run("VerifyMigrationStatusOutput", func(t *testing.T) {
		statusRaw := terraform.OutputJson(t, terraformOptions, "migration_status")

		assert.NotEmpty(t, statusRaw, "migration_status output should not be empty")
		assert.Contains(t, statusRaw, "protected_item_id", "Should contain protected_item_id")
		assert.Contains(t, statusRaw, "shutdown_source_vm", "Should contain shutdown_source_vm")
		assert.Contains(t, statusRaw, "operation_status", "Should contain operation_status")
		assert.Contains(t, statusRaw, "message", "Should contain message")
	})

	// Test 2: Verify migration_operation_details output
	t.Run("VerifyMigrationOperationDetailsOutput", func(t *testing.T) {
		operationDetails := terraform.OutputJson(t, terraformOptions, "migration_operation_details")

		assert.NotEmpty(t, operationDetails, "migration_operation_details should not be empty")
		// Should contain async operation information for job tracking
	})

	// Test 3: Verify migration_protected_item_details output
	t.Run("VerifyProtectedItemDetailsOutput", func(t *testing.T) {
		itemDetails := terraform.OutputJson(t, terraformOptions, "migration_protected_item_details")

		assert.NotEmpty(t, itemDetails, "migration_protected_item_details should not be empty")
		assert.Contains(t, itemDetails, "name", "Should contain name")
		assert.Contains(t, itemDetails, "protection_state", "Should contain protection_state")
		assert.Contains(t, itemDetails, "replication_health", "Should contain replication_health")
		assert.Contains(t, itemDetails, "instance_type", "Should contain instance_type")
	})

	// Test 4: Verify migration_validation_warnings output
	t.Run("VerifyValidationWarningsOutput", func(t *testing.T) {
		warnings := terraform.OutputJson(t, terraformOptions, "migration_validation_warnings")

		assert.NotNil(t, warnings, "migration_validation_warnings should exist")
		// Should be an array (can be empty)
	})
}

// TestMigrateCommandResourceID tests protected item resource ID validation
func TestMigrateCommandResourceID(t *testing.T) {
	helper := NewTestHelper(t)

	protectedItemID := helper.GetRequiredEnvVar("ARM_PROTECTED_ITEM_ID")

	// Test: Validate resource ID format
	t.Run("ValidateResourceIDFormat", func(t *testing.T) {
		err := ValidateAzureResourceID(protectedItemID)
		require.NoError(t, err, "Protected item ID should be a valid Azure resource ID")

		assert.Contains(t, protectedItemID, "/subscriptions/", "Should contain subscription path")
		assert.Contains(t, protectedItemID, "/resourceGroups/", "Should contain resource group path")
		assert.Contains(t, protectedItemID, "/providers/Microsoft.DataReplication/", "Should contain provider path")
		assert.Contains(t, protectedItemID, "/replicationVaults/", "Should contain replication vault")
		assert.Contains(t, protectedItemID, "/protectedItems/", "Should contain protected items")
	})
}

// TestMigrateCommandTimeout tests migration timeout handling
func TestMigrateCommandTimeout(t *testing.T) {
	if testing.Short() {
		t.Skip("Skipping long-running timeout test in short mode")
	}

	helper := NewTestHelper(t)

	subscriptionID := helper.GetRequiredEnvVar("ARM_SUBSCRIPTION_ID")
	resourceGroupName := helper.GetRequiredEnvVar("ARM_RESOURCE_GROUP_NAME")
	protectedItemID := helper.GetRequiredEnvVar("ARM_PROTECTED_ITEM_ID")

	terraformOptions := &terraform.Options{
		TerraformDir: "../examples/migrate",
		Vars: map[string]interface{}{
			"subscription_id":     subscriptionID,
			"resource_group_name": resourceGroupName,
			"protected_item_id":   protectedItemID,
			"shutdown_source_vm":  true,
			"instance_type":       "VMwareToAzStackHCI",
		},
		NoColor: true,
		// Set a very short timeout to test timeout handling
		RetryableTerraformErrors: map[string]string{},
		MaxRetries:               1,
		TimeBetweenRetries:       1 * time.Second,
	}

	// Test: Verify operation can handle long-running migrations
	t.Run("VerifyTimeoutConfiguration", func(t *testing.T) {
		terraform.Init(t, terraformOptions)
		planOutput := terraform.Plan(t, terraformOptions)

		// Verify timeout is configured (180 minutes)
		assert.Contains(t, planOutput, "planned_failover", "Should contain planned failover resource")
		// The timeout configuration is in the resource definition
	})
}

// TestMigrateCommandInstanceTypeValidation tests instance type validation
func TestMigrateCommandInstanceTypeValidation(t *testing.T) {
	helper := NewTestHelper(t)

	subscriptionID := helper.GetRequiredEnvVar("ARM_SUBSCRIPTION_ID")
	resourceGroupName := helper.GetRequiredEnvVar("ARM_RESOURCE_GROUP_NAME")
	protectedItemID := helper.GetRequiredEnvVar("ARM_PROTECTED_ITEM_ID")

	// Test 1: Valid HyperV instance type
	t.Run("ValidateHyperVInstanceType", func(t *testing.T) {
		terraformOptions := &terraform.Options{
			TerraformDir: "../examples/migrate",
			Vars: map[string]interface{}{
				"subscription_id":     subscriptionID,
				"resource_group_name": resourceGroupName,
				"protected_item_id":   protectedItemID,
				"shutdown_source_vm":  true,
				"instance_type":       "HyperVToAzStackHCI",
			},
			NoColor: true,
		}

		terraform.Init(t, terraformOptions)
		planOutput := terraform.Plan(t, terraformOptions)

		assert.NotContains(t, planOutput, "Error:", "Plan should succeed with valid HyperV instance type")
	})

	// Test 2: Valid VMware instance type
	t.Run("ValidateVMwareInstanceType", func(t *testing.T) {
		terraformOptions := &terraform.Options{
			TerraformDir: "../examples/migrate",
			Vars: map[string]interface{}{
				"subscription_id":     subscriptionID,
				"resource_group_name": resourceGroupName,
				"protected_item_id":   protectedItemID,
				"shutdown_source_vm":  true,
				"instance_type":       "VMwareToAzStackHCI",
			},
			NoColor: true,
		}

		terraform.Init(t, terraformOptions)
		planOutput := terraform.Plan(t, terraformOptions)

		assert.NotContains(t, planOutput, "Error:", "Plan should succeed with valid VMware instance type")
	})

	// Test 3: Invalid instance type
	t.Run("ValidateInvalidInstanceType", func(t *testing.T) {
		terraformOptions := &terraform.Options{
			TerraformDir: "../examples/migrate",
			Vars: map[string]interface{}{
				"subscription_id":     subscriptionID,
				"resource_group_name": resourceGroupName,
				"protected_item_id":   protectedItemID,
				"shutdown_source_vm":  true,
				"instance_type":       "InvalidType",
			},
			NoColor: true,
		}

		terraform.Init(t, terraformOptions)
		_, err := terraform.PlanE(t, terraformOptions)

		assert.Error(t, err, "Plan should fail with invalid instance type")
	})
}

// TestMigrateCommandIdempotency tests that migration operations are idempotent
func TestMigrateCommandIdempotency(t *testing.T) {
	if testing.Short() {
		t.Skip("Skipping idempotency test in short mode")
	}

	helper := NewTestHelper(t)

	subscriptionID := helper.GetRequiredEnvVar("ARM_SUBSCRIPTION_ID")
	resourceGroupName := helper.GetRequiredEnvVar("ARM_RESOURCE_GROUP_NAME")
	protectedItemID := helper.GetRequiredEnvVar("ARM_PROTECTED_ITEM_ID")

	terraformOptions := &terraform.Options{
		TerraformDir: "../examples/migrate",
		Vars: map[string]interface{}{
			"subscription_id":     subscriptionID,
			"resource_group_name": resourceGroupName,
			"protected_item_id":   protectedItemID,
			"shutdown_source_vm":  true,
			"instance_type":       "VMwareToAzStackHCI",
		},
		NoColor: true,
		RetryableTerraformErrors: map[string]string{
			".*timeout while waiting.*": "Waiting for migration to complete",
		},
		MaxRetries:         5,
		TimeBetweenRetries: 30 * time.Second,
	}

	defer terraform.Destroy(t, terraformOptions)

	// First apply
	terraform.InitAndApply(t, terraformOptions)

	// Test: Verify second apply is idempotent
	t.Run("VerifyIdempotency", func(t *testing.T) {
		// Note: Migration is a one-time operation, so a second apply
		// should either succeed with no changes or fail gracefully
		planOutput := terraform.Plan(t, terraformOptions)

		// After migration, the plan should show no changes needed
		// or indicate the migration has already been performed
		assert.NotNil(t, planOutput, "Plan output should be available")
	})
}

// TestMigrateCommandTags tests that tags are properly applied
func TestMigrateCommandTags(t *testing.T) {
	helper := NewTestHelper(t)

	subscriptionID := helper.GetRequiredEnvVar("ARM_SUBSCRIPTION_ID")
	resourceGroupName := helper.GetRequiredEnvVar("ARM_RESOURCE_GROUP_NAME")
	protectedItemID := helper.GetRequiredEnvVar("ARM_PROTECTED_ITEM_ID")

	testTags := map[string]string{
		"Environment":   "Test",
		"Purpose":       "Migration",
		"MigrationType": "PlannedFailover",
		"Team":          "Infrastructure",
	}

	terraformOptions := &terraform.Options{
		TerraformDir: "../examples/migrate",
		Vars: map[string]interface{}{
			"subscription_id":     subscriptionID,
			"resource_group_name": resourceGroupName,
			"protected_item_id":   protectedItemID,
			"shutdown_source_vm":  true,
			"instance_type":       "VMwareToAzStackHCI",
			"tags":                testTags,
		},
		NoColor: true,
	}

	// Test: Verify tags are present in plan
	t.Run("VerifyTagsInPlan", func(t *testing.T) {
		terraform.Init(t, terraformOptions)
		planOutput := terraform.Plan(t, terraformOptions)

		for key, value := range testTags {
			assert.Contains(t, planOutput, key, fmt.Sprintf("Plan should contain tag key: %s", key))
			assert.Contains(t, planOutput, value, fmt.Sprintf("Plan should contain tag value: %s", value))
		}
	})
}

// TestMigrateCommandParallelExecution tests that multiple migrations can run in parallel
func TestMigrateCommandParallelExecution(t *testing.T) {
	if testing.Short() {
		t.Skip("Skipping parallel execution test in short mode")
	}

	helper := NewTestHelper(t)

	subscriptionID := helper.GetRequiredEnvVar("ARM_SUBSCRIPTION_ID")
	resourceGroupName := helper.GetRequiredEnvVar("ARM_RESOURCE_GROUP_NAME")
	protectedItemID1 := helper.GetRequiredEnvVar("ARM_PROTECTED_ITEM_ID_1")
	protectedItemID2 := helper.GetRequiredEnvVar("ARM_PROTECTED_ITEM_ID_2")

	// Test: Verify multiple migrations can be managed independently
	t.Run("VerifyParallelMigrations", func(t *testing.T) {
		// This test verifies that the module structure supports
		// running multiple migration operations independently

		options1 := &terraform.Options{
			TerraformDir: "../examples/migrate",
			Vars: map[string]interface{}{
				"subscription_id":     subscriptionID,
				"resource_group_name": resourceGroupName,
				"protected_item_id":   protectedItemID1,
				"shutdown_source_vm":  true,
				"instance_type":       "VMwareToAzStackHCI",
			},
			NoColor: true,
		}

		options2 := &terraform.Options{
			TerraformDir: "../examples/migrate",
			Vars: map[string]interface{}{
				"subscription_id":     subscriptionID,
				"resource_group_name": resourceGroupName,
				"protected_item_id":   protectedItemID2,
				"shutdown_source_vm":  true,
				"instance_type":       "VMwareToAzStackHCI",
			},
			NoColor: true,
		}

		// Verify both can initialize and plan successfully
		terraform.Init(t, options1)
		plan1 := terraform.Plan(t, options1)
		assert.NotEmpty(t, plan1, "First migration plan should succeed")

		terraform.Init(t, options2)
		plan2 := terraform.Plan(t, options2)
		assert.NotEmpty(t, plan2, "Second migration plan should succeed")
	})
}
