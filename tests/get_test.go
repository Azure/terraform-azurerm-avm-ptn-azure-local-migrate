package test

import (
	"fmt"
	"testing"
	"time"

	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

// TestGetCommandByID tests getting a protected item by ID
func TestGetCommandByID(t *testing.T) {
	t.Parallel()

	helper := NewTestHelper(t)

	// Get required environment variables
	subscriptionID := helper.GetRequiredEnvVar("ARM_SUBSCRIPTION_ID")
	resourceGroupName := helper.GetRequiredEnvVar("ARM_RESOURCE_GROUP_NAME")
	protectedItemID := helper.GetRequiredEnvVar("ARM_PROTECTED_ITEM_ID")

	// Terraform options for get by ID
	terraformOptions := &terraform.Options{
		TerraformDir: "../examples/get",
		Vars: map[string]interface{}{
			"subscription_id":     subscriptionID,
			"resource_group_name": resourceGroupName,
			"protected_item_id":   protectedItemID,
			"instance_type":       "VMwareToAzStackHCI",
		},
		NoColor: true,
		RetryableTerraformErrors: map[string]string{
			".*timeout while waiting.*": "Waiting for get operation",
		},
		MaxRetries:         3,
		TimeBetweenRetries: 5 * time.Second,
	}

	// Cleanup after test
	defer terraform.Destroy(t, terraformOptions)

	// Run terraform init and apply
	terraform.InitAndApply(t, terraformOptions)

	// Test 1: Verify protected item is returned
	t.Run("VerifyProtectedItemReturned", func(t *testing.T) {
		protectedItem := terraform.OutputJson(t, terraformOptions, "protected_item")

		assert.NotEmpty(t, protectedItem, "Protected item should not be empty")
		assert.NotContains(t, protectedItem, "null", "Protected item should not be null")
	})

	// Test 2: Verify protected item summary
	t.Run("VerifyProtectedItemSummary", func(t *testing.T) {
		summary := terraform.OutputJson(t, terraformOptions, "protected_item_summary")

		assert.NotEmpty(t, summary, "Summary should not be empty")
		assert.Contains(t, summary, "name", "Summary should contain name")
		assert.Contains(t, summary, "protection_state", "Summary should contain protection state")
		assert.Contains(t, summary, "replication_health", "Summary should contain replication health")
	})

	// Test 3: Verify health errors output
	t.Run("VerifyHealthErrors", func(t *testing.T) {
		healthErrors := terraform.OutputJson(t, terraformOptions, "protected_item_health_errors")

		assert.NotNil(t, healthErrors, "Health errors output should not be nil")
	})

	// Test 4: Verify custom properties
	t.Run("VerifyCustomProperties", func(t *testing.T) {
		customProperties := terraform.OutputJson(t, terraformOptions, "protected_item_custom_properties")

		assert.NotEmpty(t, customProperties, "Custom properties should not be empty")
		assert.Contains(t, customProperties, "instanceType", "Custom properties should contain instance type")
	})
}

// TestGetCommandByName tests getting a protected item by name
func TestGetCommandByName(t *testing.T) {
	t.Parallel()

	helper := NewTestHelper(t)

	// Get required environment variables
	subscriptionID := helper.GetRequiredEnvVar("ARM_SUBSCRIPTION_ID")
	resourceGroupName := helper.GetRequiredEnvVar("ARM_RESOURCE_GROUP_NAME")
	protectedItemName := helper.GetRequiredEnvVar("ARM_PROTECTED_ITEM_NAME")
	projectName := helper.GetRequiredEnvVar("ARM_PROJECT_NAME")

	// Terraform options for get by name
	terraformOptions := &terraform.Options{
		TerraformDir: "../examples/get",
		Vars: map[string]interface{}{
			"subscription_id":     subscriptionID,
			"resource_group_name": resourceGroupName,
			"protected_item_name": protectedItemName,
			"project_name":        projectName,
			"instance_type":       "VMwareToAzStackHCI",
		},
		NoColor: true,
		RetryableTerraformErrors: map[string]string{
			".*timeout while waiting.*": "Waiting for get operation",
		},
		MaxRetries:         3,
		TimeBetweenRetries: 5 * time.Second,
	}

	defer terraform.Destroy(t, terraformOptions)

	// Run terraform init and apply
	terraform.InitAndApply(t, terraformOptions)

	// Test: Verify get by name works
	t.Run("VerifyGetByName", func(t *testing.T) {
		protectedItem := terraform.OutputJson(t, terraformOptions, "protected_item")

		assert.NotEmpty(t, protectedItem, "Protected item should be returned when using name lookup")
		assert.Contains(t, protectedItem, protectedItemName, "Protected item should contain the requested name")
	})

	// Test: Verify summary includes correct name
	t.Run("VerifySummaryName", func(t *testing.T) {
		summary := terraform.OutputJson(t, terraformOptions, "protected_item_summary")

		assert.Contains(t, summary, protectedItemName, "Summary should contain the protected item name")
	})
}

// TestGetCommandOutputStructure tests the structure of all get outputs
func TestGetCommandOutputStructure(t *testing.T) {
	t.Parallel()

	helper := NewTestHelper(t)

	subscriptionID := helper.GetRequiredEnvVar("ARM_SUBSCRIPTION_ID")
	resourceGroupName := helper.GetRequiredEnvVar("ARM_RESOURCE_GROUP_NAME")
	protectedItemID := helper.GetRequiredEnvVar("ARM_PROTECTED_ITEM_ID")

	terraformOptions := &terraform.Options{
		TerraformDir: "../examples/get",
		Vars: map[string]interface{}{
			"subscription_id":     subscriptionID,
			"resource_group_name": resourceGroupName,
			"protected_item_id":   protectedItemID,
			"instance_type":       "VMwareToAzStackHCI",
		},
		NoColor: true,
	}

	defer terraform.Destroy(t, terraformOptions)

	terraform.InitAndApply(t, terraformOptions)

	// Test 1: Verify protected_item structure
	t.Run("VerifyProtectedItemStructure", func(t *testing.T) {
		protectedItem := terraform.OutputJson(t, terraformOptions, "protected_item")

		assert.NotEmpty(t, protectedItem, "Protected item output should not be empty")
		// Should contain full item details
		assert.Contains(t, protectedItem, "properties", "Should contain properties")
	})

	// Test 2: Verify protected_item_summary structure
	t.Run("VerifySummaryStructure", func(t *testing.T) {
		summary := terraform.OutputJson(t, terraformOptions, "protected_item_summary")

		assert.NotEmpty(t, summary, "Summary output should not be empty")
		assert.Contains(t, summary, "name", "Should contain name")
		assert.Contains(t, summary, "protection_state", "Should contain protection state")
		assert.Contains(t, summary, "replication_health", "Should contain replication health")
		assert.Contains(t, summary, "last_successful_failover_time", "Should contain last failover time")
		assert.Contains(t, summary, "last_successful_test_failover_time", "Should contain last test failover time")
	})

	// Test 3: Verify protected_item_health_errors structure
	t.Run("VerifyHealthErrorsStructure", func(t *testing.T) {
		healthErrors := terraform.OutputJson(t, terraformOptions, "protected_item_health_errors")

		assert.NotNil(t, healthErrors, "Health errors output should not be nil")
		// Should be an array of errors (may be empty)
	})

	// Test 4: Verify protected_item_custom_properties structure
	t.Run("VerifyCustomPropertiesStructure", func(t *testing.T) {
		customProperties := terraform.OutputJson(t, terraformOptions, "protected_item_custom_properties")

		assert.NotEmpty(t, customProperties, "Custom properties should not be empty")
		assert.Contains(t, customProperties, "instanceType", "Should contain instance type")
		assert.Contains(t, customProperties, "sourceMachineName", "Should contain source machine name")
		assert.Contains(t, customProperties, "targetVmName", "Should contain target VM name")
		assert.Contains(t, customProperties, "targetResourceGroupId", "Should contain target resource group")
		assert.Contains(t, customProperties, "targetHCIClusterId", "Should contain target HCI cluster")
	})
}

// TestGetCommandValidation tests validation logic before getting item
func TestGetCommandValidation(t *testing.T) {
	t.Parallel()

	helper := NewTestHelper(t)

	subscriptionID := helper.GetRequiredEnvVar("ARM_SUBSCRIPTION_ID")
	resourceGroupName := helper.GetRequiredEnvVar("ARM_RESOURCE_GROUP_NAME")
	protectedItemID := helper.GetRequiredEnvVar("ARM_PROTECTED_ITEM_ID")

	terraformOptions := &terraform.Options{
		TerraformDir: "../examples/get",
		Vars: map[string]interface{}{
			"subscription_id":     subscriptionID,
			"resource_group_name": resourceGroupName,
			"protected_item_id":   protectedItemID,
			"instance_type":       "VMwareToAzStackHCI",
		},
		NoColor: true,
	}

	defer terraform.Destroy(t, terraformOptions)

	// Test 1: Verify plan succeeds
	t.Run("VerifyPlanSucceeds", func(t *testing.T) {
		terraform.Init(t, terraformOptions)
		planOutput := terraform.Plan(t, terraformOptions)

		assert.NotEmpty(t, planOutput, "Plan output should not be empty")
		assert.Contains(t, planOutput, "protected_item", "Plan should reference protected item")
	})

	// Test 2: Verify no errors in plan
	t.Run("VerifyNoPlanErrors", func(t *testing.T) {
		terraform.Init(t, terraformOptions)
		planOutput := terraform.Plan(t, terraformOptions)

		assert.NotContains(t, planOutput, "Error:", "Plan should not contain errors")
	})
}

// TestGetCommandInvalidID tests error handling for invalid protected item ID
func TestGetCommandInvalidID(t *testing.T) {
	t.Parallel()

	helper := NewTestHelper(t)

	subscriptionID := helper.GetRequiredEnvVar("ARM_SUBSCRIPTION_ID")
	resourceGroupName := helper.GetRequiredEnvVar("ARM_RESOURCE_GROUP_NAME")

	// Use an invalid protected item ID
	invalidItemID := fmt.Sprintf(
		"/subscriptions/%s/resourceGroups/%s/providers/Microsoft.DataReplication/replicationVaults/invalid-vault/protectedItems/invalid-item-does-not-exist",
		subscriptionID,
		resourceGroupName,
	)

	terraformOptions := &terraform.Options{
		TerraformDir: "../examples/get",
		Vars: map[string]interface{}{
			"subscription_id":     subscriptionID,
			"resource_group_name": resourceGroupName,
			"protected_item_id":   invalidItemID,
			"instance_type":       "VMwareToAzStackHCI",
		},
		NoColor: true,
	}

	// Test: Verify apply fails with invalid item ID
	t.Run("VerifyInvalidIDFails", func(t *testing.T) {
		terraform.Init(t, terraformOptions)

		_, err := terraform.ApplyE(t, terraformOptions)

		assert.Error(t, err, "Apply should fail with invalid protected item ID")
		assert.Contains(t, err.Error(), "not found", "Error should indicate item not found")
	})
}

// TestGetCommandInvalidName tests error handling for invalid protected item name
func TestGetCommandInvalidName(t *testing.T) {
	t.Parallel()

	helper := NewTestHelper(t)

	subscriptionID := helper.GetRequiredEnvVar("ARM_SUBSCRIPTION_ID")
	resourceGroupName := helper.GetRequiredEnvVar("ARM_RESOURCE_GROUP_NAME")
	projectName := helper.GetRequiredEnvVar("ARM_PROJECT_NAME")

	terraformOptions := &terraform.Options{
		TerraformDir: "../examples/get",
		Vars: map[string]interface{}{
			"subscription_id":     subscriptionID,
			"resource_group_name": resourceGroupName,
			"protected_item_name": "invalid-item-name-does-not-exist",
			"project_name":        projectName,
			"instance_type":       "VMwareToAzStackHCI",
		},
		NoColor: true,
	}

	// Test: Verify apply fails with invalid item name
	t.Run("VerifyInvalidNameFails", func(t *testing.T) {
		terraform.Init(t, terraformOptions)

		_, err := terraform.ApplyE(t, terraformOptions)

		assert.Error(t, err, "Apply should fail with invalid protected item name")
	})
}

// TestGetCommandResourceIDValidation tests resource ID format validation
func TestGetCommandResourceIDValidation(t *testing.T) {
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

// TestGetCommandInstanceTypes tests getting items for different instance types
func TestGetCommandInstanceTypes(t *testing.T) {
	t.Parallel()

	helper := NewTestHelper(t)

	subscriptionID := helper.GetRequiredEnvVar("ARM_SUBSCRIPTION_ID")
	resourceGroupName := helper.GetRequiredEnvVar("ARM_RESOURCE_GROUP_NAME")

	// Test VMware instance type
	t.Run("GetVMwareItem", func(t *testing.T) {
		protectedItemID := helper.GetRequiredEnvVar("ARM_PROTECTED_ITEM_ID_VMWARE")

		terraformOptions := &terraform.Options{
			TerraformDir: "../examples/get",
			Vars: map[string]interface{}{
				"subscription_id":     subscriptionID,
				"resource_group_name": resourceGroupName,
				"protected_item_id":   protectedItemID,
				"instance_type":       "VMwareToAzStackHCI",
			},
			NoColor: true,
		}

		defer terraform.Destroy(t, terraformOptions)

		terraform.InitAndApply(t, terraformOptions)

		customProperties := terraform.OutputJson(t, terraformOptions, "protected_item_custom_properties")
		assert.Contains(t, customProperties, "VMwareToAzStackHCI", "Should contain VMware instance type")
	})

	// Test HyperV instance type
	t.Run("GetHyperVItem", func(t *testing.T) {
		protectedItemID := helper.GetRequiredEnvVar("ARM_PROTECTED_ITEM_ID_HYPERV")

		terraformOptions := &terraform.Options{
			TerraformDir: "../examples/get",
			Vars: map[string]interface{}{
				"subscription_id":     subscriptionID,
				"resource_group_name": resourceGroupName,
				"protected_item_id":   protectedItemID,
				"instance_type":       "HyperVToAzStackHCI",
			},
			NoColor: true,
		}

		defer terraform.Destroy(t, terraformOptions)

		terraform.InitAndApply(t, terraformOptions)

		customProperties := terraform.OutputJson(t, terraformOptions, "protected_item_custom_properties")
		assert.Contains(t, customProperties, "HyperVToAzStackHCI", "Should contain HyperV instance type")
	})
}

// TestGetCommandPerformance tests get operation performance
func TestGetCommandPerformance(t *testing.T) {
	if testing.Short() {
		t.Skip("Skipping performance test in short mode")
	}

	helper := NewTestHelper(t)

	subscriptionID := helper.GetRequiredEnvVar("ARM_SUBSCRIPTION_ID")
	resourceGroupName := helper.GetRequiredEnvVar("ARM_RESOURCE_GROUP_NAME")
	protectedItemID := helper.GetRequiredEnvVar("ARM_PROTECTED_ITEM_ID")

	terraformOptions := &terraform.Options{
		TerraformDir: "../examples/get",
		Vars: map[string]interface{}{
			"subscription_id":     subscriptionID,
			"resource_group_name": resourceGroupName,
			"protected_item_id":   protectedItemID,
			"instance_type":       "VMwareToAzStackHCI",
		},
		NoColor: true,
	}

	defer terraform.Destroy(t, terraformOptions)

	// Test: Verify get operation completes in reasonable time
	t.Run("VerifyGetPerformance", func(t *testing.T) {
		startTime := time.Now()

		terraform.InitAndApply(t, terraformOptions)

		duration := time.Since(startTime)

		// Get operation should complete within 1 minute
		assert.Less(t, duration.Minutes(), 1.0, "Get operation should complete within 1 minute")
	})
}

// TestGetCommandIdempotency tests that get operations are idempotent
func TestGetCommandIdempotency(t *testing.T) {
	t.Parallel()

	helper := NewTestHelper(t)

	subscriptionID := helper.GetRequiredEnvVar("ARM_SUBSCRIPTION_ID")
	resourceGroupName := helper.GetRequiredEnvVar("ARM_RESOURCE_GROUP_NAME")
	protectedItemID := helper.GetRequiredEnvVar("ARM_PROTECTED_ITEM_ID")

	terraformOptions := &terraform.Options{
		TerraformDir: "../examples/get",
		Vars: map[string]interface{}{
			"subscription_id":     subscriptionID,
			"resource_group_name": resourceGroupName,
			"protected_item_id":   protectedItemID,
			"instance_type":       "VMwareToAzStackHCI",
		},
		NoColor: true,
	}

	defer terraform.Destroy(t, terraformOptions)

	// First apply
	terraform.InitAndApply(t, terraformOptions)
	firstOutput := terraform.OutputJson(t, terraformOptions, "protected_item")

	// Test: Verify second apply is idempotent
	t.Run("VerifyIdempotency", func(t *testing.T) {
		// Second apply should show no changes
		planOutput := terraform.Plan(t, terraformOptions)

		assert.Contains(t, planOutput, "No changes", "Second plan should show no changes")

		// Re-apply and verify output is consistent
		terraform.Apply(t, terraformOptions)
		secondOutput := terraform.OutputJson(t, terraformOptions, "protected_item")

		assert.Equal(t, firstOutput, secondOutput, "Output should be identical between applies")
	})
}

// TestGetCommandTags tests that tags are properly applied
func TestGetCommandTags(t *testing.T) {
	helper := NewTestHelper(t)

	subscriptionID := helper.GetRequiredEnvVar("ARM_SUBSCRIPTION_ID")
	resourceGroupName := helper.GetRequiredEnvVar("ARM_RESOURCE_GROUP_NAME")
	protectedItemID := helper.GetRequiredEnvVar("ARM_PROTECTED_ITEM_ID")

	testTags := map[string]string{
		"Environment": "Test",
		"Purpose":     "GetProtectedItem",
		"Team":        "Infrastructure",
		"Module":      "AzureMigrate",
	}

	terraformOptions := &terraform.Options{
		TerraformDir: "../examples/get",
		Vars: map[string]interface{}{
			"subscription_id":     subscriptionID,
			"resource_group_name": resourceGroupName,
			"protected_item_id":   protectedItemID,
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

// TestGetCommandHealthStatus tests health status retrieval
func TestGetCommandHealthStatus(t *testing.T) {
	t.Parallel()

	helper := NewTestHelper(t)

	subscriptionID := helper.GetRequiredEnvVar("ARM_SUBSCRIPTION_ID")
	resourceGroupName := helper.GetRequiredEnvVar("ARM_RESOURCE_GROUP_NAME")
	protectedItemID := helper.GetRequiredEnvVar("ARM_PROTECTED_ITEM_ID")

	terraformOptions := &terraform.Options{
		TerraformDir: "../examples/get",
		Vars: map[string]interface{}{
			"subscription_id":     subscriptionID,
			"resource_group_name": resourceGroupName,
			"protected_item_id":   protectedItemID,
			"instance_type":       "VMwareToAzStackHCI",
		},
		NoColor: true,
	}

	defer terraform.Destroy(t, terraformOptions)

	terraform.InitAndApply(t, terraformOptions)

	// Test 1: Verify health status is included
	t.Run("VerifyHealthStatus", func(t *testing.T) {
		summary := terraform.OutputJson(t, terraformOptions, "protected_item_summary")

		assert.Contains(t, summary, "replication_health", "Summary should contain replication health")

		// Health status should be one of the valid values (Normal, Warning, Critical, None)
		// We can't assert exact value as it's dynamic
		assert.NotEmpty(t, summary, "Health status should be present")
	}) // Test 2: Verify health errors format
	t.Run("VerifyHealthErrorsFormat", func(t *testing.T) {
		healthErrors := terraform.OutputJson(t, terraformOptions, "protected_item_health_errors")

		assert.NotNil(t, healthErrors, "Health errors should not be nil")
		// Should be an array (may be empty if no errors)
	})
}

// TestGetCommandProtectionState tests protection state retrieval
func TestGetCommandProtectionState(t *testing.T) {
	t.Parallel()

	helper := NewTestHelper(t)

	subscriptionID := helper.GetRequiredEnvVar("ARM_SUBSCRIPTION_ID")
	resourceGroupName := helper.GetRequiredEnvVar("ARM_RESOURCE_GROUP_NAME")
	protectedItemID := helper.GetRequiredEnvVar("ARM_PROTECTED_ITEM_ID")

	terraformOptions := &terraform.Options{
		TerraformDir: "../examples/get",
		Vars: map[string]interface{}{
			"subscription_id":     subscriptionID,
			"resource_group_name": resourceGroupName,
			"protected_item_id":   protectedItemID,
			"instance_type":       "VMwareToAzStackHCI",
		},
		NoColor: true,
	}

	defer terraform.Destroy(t, terraformOptions)

	terraform.InitAndApply(t, terraformOptions)

	// Test: Verify protection state is included
	t.Run("VerifyProtectionState", func(t *testing.T) {
		summary := terraform.OutputJson(t, terraformOptions, "protected_item_summary")

		assert.Contains(t, summary, "protection_state", "Summary should contain protection state")
		assert.NotEmpty(t, summary, "Protection state should be present")
	})
}

// TestGetCommandConcurrentAccess tests concurrent get operations
func TestGetCommandConcurrentAccess(t *testing.T) {
	if testing.Short() {
		t.Skip("Skipping concurrent access test in short mode")
	}

	helper := NewTestHelper(t)

	subscriptionID := helper.GetRequiredEnvVar("ARM_SUBSCRIPTION_ID")
	resourceGroupName := helper.GetRequiredEnvVar("ARM_RESOURCE_GROUP_NAME")
	protectedItemID := helper.GetRequiredEnvVar("ARM_PROTECTED_ITEM_ID")

	// Test: Verify multiple concurrent get operations work correctly
	t.Run("VerifyConcurrentGetOperations", func(t *testing.T) {
		options1 := &terraform.Options{
			TerraformDir: "../examples/get",
			Vars: map[string]interface{}{
				"subscription_id":     subscriptionID,
				"resource_group_name": resourceGroupName,
				"protected_item_id":   protectedItemID,
				"instance_type":       "VMwareToAzStackHCI",
			},
			NoColor: true,
		}

		options2 := &terraform.Options{
			TerraformDir: "../examples/get",
			Vars: map[string]interface{}{
				"subscription_id":     subscriptionID,
				"resource_group_name": resourceGroupName,
				"protected_item_id":   protectedItemID,
				"instance_type":       "VMwareToAzStackHCI",
			},
			NoColor: true,
		}

		// Both should be able to initialize and plan successfully
		terraform.Init(t, options1)
		plan1 := terraform.Plan(t, options1)
		assert.NotEmpty(t, plan1, "First get plan should succeed")

		terraform.Init(t, options2)
		plan2 := terraform.Plan(t, options2)
		assert.NotEmpty(t, plan2, "Second get plan should succeed")
	})
}

// TestGetCommandOutputConsistency tests output consistency across multiple reads
func TestGetCommandOutputConsistency(t *testing.T) {
	if testing.Short() {
		t.Skip("Skipping output consistency test in short mode")
	}

	helper := NewTestHelper(t)

	subscriptionID := helper.GetRequiredEnvVar("ARM_SUBSCRIPTION_ID")
	resourceGroupName := helper.GetRequiredEnvVar("ARM_RESOURCE_GROUP_NAME")
	protectedItemID := helper.GetRequiredEnvVar("ARM_PROTECTED_ITEM_ID")

	terraformOptions := &terraform.Options{
		TerraformDir: "../examples/get",
		Vars: map[string]interface{}{
			"subscription_id":     subscriptionID,
			"resource_group_name": resourceGroupName,
			"protected_item_id":   protectedItemID,
			"instance_type":       "VMwareToAzStackHCI",
		},
		NoColor: true,
	}

	defer terraform.Destroy(t, terraformOptions)

	terraform.InitAndApply(t, terraformOptions)

	// Test: Verify outputs are consistent across multiple reads
	t.Run("VerifyOutputConsistency", func(t *testing.T) {
		item1 := terraform.OutputJson(t, terraformOptions, "protected_item")
		item2 := terraform.OutputJson(t, terraformOptions, "protected_item")

		assert.Equal(t, item1, item2, "Protected item should be consistent across reads")

		summary1 := terraform.OutputJson(t, terraformOptions, "protected_item_summary")
		summary2 := terraform.OutputJson(t, terraformOptions, "protected_item_summary")

		assert.Equal(t, summary1, summary2, "Summary should be consistent across reads")
	})
}

// TestGetCommandWithVaultID tests get operation with explicit vault ID
func TestGetCommandWithVaultID(t *testing.T) {
	t.Parallel()

	helper := NewTestHelper(t)

	subscriptionID := helper.GetRequiredEnvVar("ARM_SUBSCRIPTION_ID")
	resourceGroupName := helper.GetRequiredEnvVar("ARM_RESOURCE_GROUP_NAME")
	protectedItemName := helper.GetRequiredEnvVar("ARM_PROTECTED_ITEM_NAME")
	vaultID := helper.GetRequiredEnvVar("ARM_REPLICATION_VAULT_ID")

	terraformOptions := &terraform.Options{
		TerraformDir: "../examples/get",
		Vars: map[string]interface{}{
			"subscription_id":      subscriptionID,
			"resource_group_name":  resourceGroupName,
			"protected_item_name":  protectedItemName,
			"replication_vault_id": vaultID,
			"instance_type":        "VMwareToAzStackHCI",
		},
		NoColor: true,
	}

	defer terraform.Destroy(t, terraformOptions)

	terraform.InitAndApply(t, terraformOptions)

	// Test: Verify get with vault ID works
	t.Run("VerifyGetWithVaultID", func(t *testing.T) {
		protectedItem := terraform.OutputJson(t, terraformOptions, "protected_item")

		assert.NotEmpty(t, protectedItem, "Protected item should be returned when using vault ID")
	})
}
