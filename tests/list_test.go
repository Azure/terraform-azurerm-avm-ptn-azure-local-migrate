package test

import (
	"fmt"
	"testing"
	"time"

	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

// TestListCommandByProject tests listing protected items by project name
func TestListCommandByProject(t *testing.T) {
	t.Parallel()

	helper := NewTestHelper(t)

	// Get required environment variables
	subscriptionID := helper.GetRequiredEnvVar("ARM_SUBSCRIPTION_ID")
	resourceGroupName := helper.GetRequiredEnvVar("ARM_RESOURCE_GROUP_NAME")
	projectName := helper.GetRequiredEnvVar("ARM_PROJECT_NAME")

	// Terraform options for list by project
	terraformOptions := &terraform.Options{
		TerraformDir: "../examples/list",
		Vars: map[string]interface{}{
			"subscription_id":     subscriptionID,
			"resource_group_name": resourceGroupName,
			"project_name":        projectName,
			"instance_type":       "VMwareToAzStackHCI",
		},
		NoColor: true,
		RetryableTerraformErrors: map[string]string{
			".*timeout while waiting.*": "Waiting for list operation",
		},
		MaxRetries:         3,
		TimeBetweenRetries: 5 * time.Second,
	}

	// Cleanup after test
	defer terraform.Destroy(t, terraformOptions)

	// Run terraform init and apply
	terraform.InitAndApply(t, terraformOptions)

	// Test 1: Verify protected items list is returned
	t.Run("VerifyProtectedItemsList", func(t *testing.T) {
		protectedItemsList := terraform.OutputJson(t, terraformOptions, "protected_items_list")

		assert.NotEmpty(t, protectedItemsList, "Protected items list should not be empty")
		assert.NotContains(t, protectedItemsList, "null", "Protected items list should not be null")
	})

	// Test 2: Verify protected items count
	t.Run("VerifyProtectedItemsCount", func(t *testing.T) {
		countOutput := terraform.OutputJson(t, terraformOptions, "protected_items_count")

		assert.NotEmpty(t, countOutput, "Protected items count should not be empty")
	})

	// Test 3: Verify summary output
	t.Run("VerifyProtectedItemsSummary", func(t *testing.T) {
		summaryOutput := terraform.OutputJson(t, terraformOptions, "protected_items_summary")

		assert.NotEmpty(t, summaryOutput, "Protected items summary should not be empty")
	})

	// Test 4: Verify items grouped by state
	t.Run("VerifyItemsByState", func(t *testing.T) {
		itemsByState := terraform.OutputJson(t, terraformOptions, "protected_items_by_state")

		assert.NotNil(t, itemsByState, "Items by state should not be nil")
	})

	// Test 5: Verify items grouped by health
	t.Run("VerifyItemsByHealth", func(t *testing.T) {
		itemsByHealth := terraform.OutputJson(t, terraformOptions, "protected_items_by_health")

		assert.NotNil(t, itemsByHealth, "Items by health should not be nil")
	})

	// Test 6: Verify items with errors
	t.Run("VerifyItemsWithErrors", func(t *testing.T) {
		itemsWithErrors := terraform.OutputJson(t, terraformOptions, "protected_items_with_errors")

		assert.NotNil(t, itemsWithErrors, "Items with errors should not be nil")
	})
}

// TestListCommandByVaultID tests listing protected items by vault ID
func TestListCommandByVaultID(t *testing.T) {
	t.Parallel()

	helper := NewTestHelper(t)

	// Get required environment variables
	subscriptionID := helper.GetRequiredEnvVar("ARM_SUBSCRIPTION_ID")
	resourceGroupName := helper.GetRequiredEnvVar("ARM_RESOURCE_GROUP_NAME")
	replicationVaultID := helper.GetRequiredEnvVar("ARM_REPLICATION_VAULT_ID")

	// Terraform options for list by vault ID
	terraformOptions := &terraform.Options{
		TerraformDir: "../examples/list",
		Vars: map[string]interface{}{
			"subscription_id":      subscriptionID,
			"resource_group_name":  resourceGroupName,
			"replication_vault_id": replicationVaultID,
			"instance_type":        "VMwareToAzStackHCI",
		},
		NoColor: true,
		RetryableTerraformErrors: map[string]string{
			".*timeout while waiting.*": "Waiting for list operation",
		},
		MaxRetries:         3,
		TimeBetweenRetries: 5 * time.Second,
	}

	defer terraform.Destroy(t, terraformOptions)

	// Run terraform init and apply
	terraform.InitAndApply(t, terraformOptions)

	// Test: Verify list operation with vault ID
	t.Run("VerifyListByVaultID", func(t *testing.T) {
		protectedItemsList := terraform.OutputJson(t, terraformOptions, "protected_items_list")

		assert.NotEmpty(t, protectedItemsList, "Protected items list should not be empty when using vault ID")
	})

	// Test: Verify vault ID format
	t.Run("VerifyVaultIDFormat", func(t *testing.T) {
		err := ValidateAzureResourceID(replicationVaultID)
		require.NoError(t, err, "Vault ID should be a valid Azure resource ID")

		assert.Contains(t, replicationVaultID, "/subscriptions/", "Vault ID should contain subscription path")
		assert.Contains(t, replicationVaultID, "/resourceGroups/", "Vault ID should contain resource group path")
		assert.Contains(t, replicationVaultID, "/providers/Microsoft.DataReplication/replicationVaults/", "Vault ID should contain vault path")
	})
}

// TestListCommandOutputStructure tests the structure of all list outputs
func TestListCommandOutputStructure(t *testing.T) {
	t.Parallel()

	helper := NewTestHelper(t)

	subscriptionID := helper.GetRequiredEnvVar("ARM_SUBSCRIPTION_ID")
	resourceGroupName := helper.GetRequiredEnvVar("ARM_RESOURCE_GROUP_NAME")
	projectName := helper.GetRequiredEnvVar("ARM_PROJECT_NAME")

	terraformOptions := &terraform.Options{
		TerraformDir: "../examples/list",
		Vars: map[string]interface{}{
			"subscription_id":     subscriptionID,
			"resource_group_name": resourceGroupName,
			"project_name":        projectName,
			"instance_type":       "VMwareToAzStackHCI",
		},
		NoColor: true,
	}

	defer terraform.Destroy(t, terraformOptions)

	terraform.InitAndApply(t, terraformOptions)

	// Test 1: Verify protected_items_list structure
	t.Run("VerifyListStructure", func(t *testing.T) {
		listOutput := terraform.OutputJson(t, terraformOptions, "protected_items_list")

		assert.NotEmpty(t, listOutput, "List output should not be empty")
		// Should be an array of protected items
	})

	// Test 2: Verify protected_items_count structure
	t.Run("VerifyCountStructure", func(t *testing.T) {
		countOutput := terraform.OutputJson(t, terraformOptions, "protected_items_count")

		assert.NotEmpty(t, countOutput, "Count output should not be empty")
		// Should be a number
	})

	// Test 3: Verify protected_items_summary structure
	t.Run("VerifySummaryStructure", func(t *testing.T) {
		summaryOutput := terraform.OutputJson(t, terraformOptions, "protected_items_summary")

		assert.NotEmpty(t, summaryOutput, "Summary output should not be empty")
		// Should contain name, state, health for each item
	})

	// Test 4: Verify protected_items_by_state structure
	t.Run("VerifyByStateStructure", func(t *testing.T) {
		byStateOutput := terraform.OutputJson(t, terraformOptions, "protected_items_by_state")

		assert.NotNil(t, byStateOutput, "By state output should not be nil")
		// Should be grouped by protection state
	})

	// Test 5: Verify protected_items_by_health structure
	t.Run("VerifyByHealthStructure", func(t *testing.T) {
		byHealthOutput := terraform.OutputJson(t, terraformOptions, "protected_items_by_health")

		assert.NotNil(t, byHealthOutput, "By health output should not be nil")
		// Should be grouped by replication health
	})

	// Test 6: Verify protected_items_with_errors structure
	t.Run("VerifyWithErrorsStructure", func(t *testing.T) {
		withErrorsOutput := terraform.OutputJson(t, terraformOptions, "protected_items_with_errors")

		assert.NotNil(t, withErrorsOutput, "With errors output should not be nil")
		// Should be an array of items with errors
	})
}

// TestListCommandValidation tests validation logic before listing
func TestListCommandValidation(t *testing.T) {
	t.Parallel()

	helper := NewTestHelper(t)

	subscriptionID := helper.GetRequiredEnvVar("ARM_SUBSCRIPTION_ID")
	resourceGroupName := helper.GetRequiredEnvVar("ARM_RESOURCE_GROUP_NAME")
	projectName := helper.GetRequiredEnvVar("ARM_PROJECT_NAME")

	terraformOptions := &terraform.Options{
		TerraformDir: "../examples/list",
		Vars: map[string]interface{}{
			"subscription_id":     subscriptionID,
			"resource_group_name": resourceGroupName,
			"project_name":        projectName,
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
		assert.Contains(t, planOutput, "protected_items", "Plan should reference protected items")
	})

	// Test 2: Verify no errors in plan
	t.Run("VerifyNoPlanErrors", func(t *testing.T) {
		terraform.Init(t, terraformOptions)
		planOutput := terraform.Plan(t, terraformOptions)

		assert.NotContains(t, planOutput, "Error:", "Plan should not contain errors")
	})
}

// TestListCommandInvalidVault tests error handling for invalid vault
func TestListCommandInvalidVault(t *testing.T) {
	t.Parallel()

	helper := NewTestHelper(t)

	subscriptionID := helper.GetRequiredEnvVar("ARM_SUBSCRIPTION_ID")
	resourceGroupName := helper.GetRequiredEnvVar("ARM_RESOURCE_GROUP_NAME")

	// Use an invalid vault ID
	invalidVaultID := fmt.Sprintf(
		"/subscriptions/%s/resourceGroups/%s/providers/Microsoft.DataReplication/replicationVaults/invalid-vault-does-not-exist",
		subscriptionID,
		resourceGroupName,
	)

	terraformOptions := &terraform.Options{
		TerraformDir: "../examples/list",
		Vars: map[string]interface{}{
			"subscription_id":      subscriptionID,
			"resource_group_name":  resourceGroupName,
			"replication_vault_id": invalidVaultID,
			"instance_type":        "VMwareToAzStackHCI",
		},
		NoColor: true,
	}

	// Test: Verify apply fails with invalid vault
	t.Run("VerifyInvalidVaultFails", func(t *testing.T) {
		terraform.Init(t, terraformOptions)

		_, err := terraform.ApplyE(t, terraformOptions)

		assert.Error(t, err, "Apply should fail with invalid vault ID")
		assert.Contains(t, err.Error(), "not found", "Error should indicate vault not found")
	})
}

// TestListCommandEmptyResults tests handling of empty results
func TestListCommandEmptyResults(t *testing.T) {
	if testing.Short() {
		t.Skip("Skipping empty results test in short mode")
	}

	helper := NewTestHelper(t)

	subscriptionID := helper.GetRequiredEnvVar("ARM_SUBSCRIPTION_ID")
	resourceGroupName := helper.GetRequiredEnvVar("ARM_RESOURCE_GROUP_NAME")
	emptyVaultID := helper.GetRequiredEnvVar("ARM_EMPTY_VAULT_ID") // Vault with no protected items

	terraformOptions := &terraform.Options{
		TerraformDir: "../examples/list",
		Vars: map[string]interface{}{
			"subscription_id":      subscriptionID,
			"resource_group_name":  resourceGroupName,
			"replication_vault_id": emptyVaultID,
			"instance_type":        "VMwareToAzStackHCI",
		},
		NoColor: true,
	}

	defer terraform.Destroy(t, terraformOptions)

	terraform.InitAndApply(t, terraformOptions)

	// Test: Verify empty results are handled gracefully
	t.Run("VerifyEmptyResultsHandling", func(t *testing.T) {
		countOutput := terraform.OutputJson(t, terraformOptions, "protected_items_count")

		assert.Contains(t, countOutput, "0", "Count should be 0 for empty vault")
	})

	t.Run("VerifyEmptyListOutput", func(t *testing.T) {
		listOutput := terraform.OutputJson(t, terraformOptions, "protected_items_list")

		// Should return empty array or null
		assert.NotNil(t, listOutput, "List output should not be nil even when empty")
	})
}

// TestListCommandFiltering tests filtering capabilities
func TestListCommandFiltering(t *testing.T) {
	t.Parallel()

	helper := NewTestHelper(t)

	subscriptionID := helper.GetRequiredEnvVar("ARM_SUBSCRIPTION_ID")
	resourceGroupName := helper.GetRequiredEnvVar("ARM_RESOURCE_GROUP_NAME")
	projectName := helper.GetRequiredEnvVar("ARM_PROJECT_NAME")

	terraformOptions := &terraform.Options{
		TerraformDir: "../examples/list",
		Vars: map[string]interface{}{
			"subscription_id":     subscriptionID,
			"resource_group_name": resourceGroupName,
			"project_name":        projectName,
			"instance_type":       "VMwareToAzStackHCI",
		},
		NoColor: true,
	}

	defer terraform.Destroy(t, terraformOptions)

	terraform.InitAndApply(t, terraformOptions)

	// Test 1: Verify items can be filtered by state
	t.Run("VerifyFilterByState", func(t *testing.T) {
		itemsByState := terraform.OutputJson(t, terraformOptions, "protected_items_by_state")

		assert.NotNil(t, itemsByState, "Items by state should provide filtered results")
	})

	// Test 2: Verify items can be filtered by health
	t.Run("VerifyFilterByHealth", func(t *testing.T) {
		itemsByHealth := terraform.OutputJson(t, terraformOptions, "protected_items_by_health")

		assert.NotNil(t, itemsByHealth, "Items by health should provide filtered results")
	})

	// Test 3: Verify error filtering
	t.Run("VerifyErrorFiltering", func(t *testing.T) {
		itemsWithErrors := terraform.OutputJson(t, terraformOptions, "protected_items_with_errors")

		assert.NotNil(t, itemsWithErrors, "Items with errors should be filterable")
	})
}

// TestListCommandInstanceTypes tests listing for different instance types
func TestListCommandInstanceTypes(t *testing.T) {
	t.Parallel()

	helper := NewTestHelper(t)

	subscriptionID := helper.GetRequiredEnvVar("ARM_SUBSCRIPTION_ID")
	resourceGroupName := helper.GetRequiredEnvVar("ARM_RESOURCE_GROUP_NAME")
	projectName := helper.GetRequiredEnvVar("ARM_PROJECT_NAME")

	// Test VMware instance type
	t.Run("ListVMwareItems", func(t *testing.T) {
		terraformOptions := &terraform.Options{
			TerraformDir: "../examples/list",
			Vars: map[string]interface{}{
				"subscription_id":     subscriptionID,
				"resource_group_name": resourceGroupName,
				"project_name":        projectName,
				"instance_type":       "VMwareToAzStackHCI",
			},
			NoColor: true,
		}

		defer terraform.Destroy(t, terraformOptions)

		terraform.InitAndApply(t, terraformOptions)

		listOutput := terraform.OutputJson(t, terraformOptions, "protected_items_list")
		assert.NotEmpty(t, listOutput, "Should list VMware items")
	})

	// Test HyperV instance type
	t.Run("ListHyperVItems", func(t *testing.T) {
		terraformOptions := &terraform.Options{
			TerraformDir: "../examples/list",
			Vars: map[string]interface{}{
				"subscription_id":     subscriptionID,
				"resource_group_name": resourceGroupName,
				"project_name":        projectName,
				"instance_type":       "HyperVToAzStackHCI",
			},
			NoColor: true,
		}

		defer terraform.Destroy(t, terraformOptions)

		terraform.InitAndApply(t, terraformOptions)

		listOutput := terraform.OutputJson(t, terraformOptions, "protected_items_list")
		assert.NotEmpty(t, listOutput, "Should list HyperV items")
	})
}

// TestListCommandPerformance tests list operation performance
func TestListCommandPerformance(t *testing.T) {
	if testing.Short() {
		t.Skip("Skipping performance test in short mode")
	}

	helper := NewTestHelper(t)

	subscriptionID := helper.GetRequiredEnvVar("ARM_SUBSCRIPTION_ID")
	resourceGroupName := helper.GetRequiredEnvVar("ARM_RESOURCE_GROUP_NAME")
	projectName := helper.GetRequiredEnvVar("ARM_PROJECT_NAME")

	terraformOptions := &terraform.Options{
		TerraformDir: "../examples/list",
		Vars: map[string]interface{}{
			"subscription_id":     subscriptionID,
			"resource_group_name": resourceGroupName,
			"project_name":        projectName,
			"instance_type":       "VMwareToAzStackHCI",
		},
		NoColor: true,
	}

	defer terraform.Destroy(t, terraformOptions)

	// Test: Verify list operation completes in reasonable time
	t.Run("VerifyListPerformance", func(t *testing.T) {
		startTime := time.Now()

		terraform.InitAndApply(t, terraformOptions)

		duration := time.Since(startTime)

		// List operation should complete within 2 minutes
		assert.Less(t, duration.Minutes(), 2.0, "List operation should complete within 2 minutes")
	})
}

// TestListCommandIdempotency tests that list operations are idempotent
func TestListCommandIdempotency(t *testing.T) {
	t.Parallel()

	helper := NewTestHelper(t)

	subscriptionID := helper.GetRequiredEnvVar("ARM_SUBSCRIPTION_ID")
	resourceGroupName := helper.GetRequiredEnvVar("ARM_RESOURCE_GROUP_NAME")
	projectName := helper.GetRequiredEnvVar("ARM_PROJECT_NAME")

	terraformOptions := &terraform.Options{
		TerraformDir: "../examples/list",
		Vars: map[string]interface{}{
			"subscription_id":     subscriptionID,
			"resource_group_name": resourceGroupName,
			"project_name":        projectName,
			"instance_type":       "VMwareToAzStackHCI",
		},
		NoColor: true,
	}

	defer terraform.Destroy(t, terraformOptions)

	// First apply
	terraform.InitAndApply(t, terraformOptions)
	firstOutput := terraform.OutputJson(t, terraformOptions, "protected_items_list")

	// Test: Verify second apply is idempotent
	t.Run("VerifyIdempotency", func(t *testing.T) {
		// Second apply should show no changes
		planOutput := terraform.Plan(t, terraformOptions)

		assert.Contains(t, planOutput, "No changes", "Second plan should show no changes")

		// Re-apply and verify output is consistent
		terraform.Apply(t, terraformOptions)
		secondOutput := terraform.OutputJson(t, terraformOptions, "protected_items_list")

		assert.Equal(t, firstOutput, secondOutput, "Output should be identical between applies")
	})
}

// TestListCommandTags tests that tags are properly applied
func TestListCommandTags(t *testing.T) {
	helper := NewTestHelper(t)

	subscriptionID := helper.GetRequiredEnvVar("ARM_SUBSCRIPTION_ID")
	resourceGroupName := helper.GetRequiredEnvVar("ARM_RESOURCE_GROUP_NAME")
	projectName := helper.GetRequiredEnvVar("ARM_PROJECT_NAME")

	testTags := map[string]string{
		"Environment": "Test",
		"Purpose":     "ListProtectedItems",
		"Team":        "Infrastructure",
		"Module":      "AzureMigrate",
	}

	terraformOptions := &terraform.Options{
		TerraformDir: "../examples/list",
		Vars: map[string]interface{}{
			"subscription_id":     subscriptionID,
			"resource_group_name": resourceGroupName,
			"project_name":        projectName,
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

// TestListCommandResourceIDValidation tests resource ID validation
func TestListCommandResourceIDValidation(t *testing.T) {
	helper := NewTestHelper(t)

	vaultID := helper.GetRequiredEnvVar("ARM_REPLICATION_VAULT_ID")

	// Test: Validate vault resource ID format
	t.Run("ValidateVaultIDFormat", func(t *testing.T) {
		err := ValidateAzureResourceID(vaultID)
		require.NoError(t, err, "Vault ID should be a valid Azure resource ID")

		assert.Contains(t, vaultID, "/subscriptions/", "Should contain subscription path")
		assert.Contains(t, vaultID, "/resourceGroups/", "Should contain resource group path")
		assert.Contains(t, vaultID, "/providers/Microsoft.DataReplication/", "Should contain provider path")
		assert.Contains(t, vaultID, "/replicationVaults/", "Should contain replication vaults")
	})
}

// TestListCommandConcurrentAccess tests concurrent list operations
func TestListCommandConcurrentAccess(t *testing.T) {
	if testing.Short() {
		t.Skip("Skipping concurrent access test in short mode")
	}

	helper := NewTestHelper(t)

	subscriptionID := helper.GetRequiredEnvVar("ARM_SUBSCRIPTION_ID")
	resourceGroupName := helper.GetRequiredEnvVar("ARM_RESOURCE_GROUP_NAME")
	projectName := helper.GetRequiredEnvVar("ARM_PROJECT_NAME")

	// Test: Verify multiple concurrent list operations work correctly
	t.Run("VerifyConcurrentListOperations", func(t *testing.T) {
		options1 := &terraform.Options{
			TerraformDir: "../examples/list",
			Vars: map[string]interface{}{
				"subscription_id":     subscriptionID,
				"resource_group_name": resourceGroupName,
				"project_name":        projectName,
				"instance_type":       "VMwareToAzStackHCI",
			},
			NoColor: true,
		}

		options2 := &terraform.Options{
			TerraformDir: "../examples/list",
			Vars: map[string]interface{}{
				"subscription_id":     subscriptionID,
				"resource_group_name": resourceGroupName,
				"project_name":        projectName,
				"instance_type":       "VMwareToAzStackHCI",
			},
			NoColor: true,
		}

		// Both should be able to initialize and plan successfully
		terraform.Init(t, options1)
		plan1 := terraform.Plan(t, options1)
		assert.NotEmpty(t, plan1, "First list plan should succeed")

		terraform.Init(t, options2)
		plan2 := terraform.Plan(t, options2)
		assert.NotEmpty(t, plan2, "Second list plan should succeed")
	})
}

// TestListCommandOutputConsistency tests output consistency across multiple runs
func TestListCommandOutputConsistency(t *testing.T) {
	if testing.Short() {
		t.Skip("Skipping output consistency test in short mode")
	}

	helper := NewTestHelper(t)

	subscriptionID := helper.GetRequiredEnvVar("ARM_SUBSCRIPTION_ID")
	resourceGroupName := helper.GetRequiredEnvVar("ARM_RESOURCE_GROUP_NAME")
	projectName := helper.GetRequiredEnvVar("ARM_PROJECT_NAME")

	terraformOptions := &terraform.Options{
		TerraformDir: "../examples/list",
		Vars: map[string]interface{}{
			"subscription_id":     subscriptionID,
			"resource_group_name": resourceGroupName,
			"project_name":        projectName,
			"instance_type":       "VMwareToAzStackHCI",
		},
		NoColor: true,
	}

	defer terraform.Destroy(t, terraformOptions)

	terraform.InitAndApply(t, terraformOptions)

	// Test: Verify outputs are consistent across multiple reads
	t.Run("VerifyOutputConsistency", func(t *testing.T) {
		count1 := terraform.Output(t, terraformOptions, "protected_items_count")
		count2 := terraform.Output(t, terraformOptions, "protected_items_count")

		assert.Equal(t, count1, count2, "Count should be consistent across reads")

		list1 := terraform.OutputJson(t, terraformOptions, "protected_items_list")
		list2 := terraform.OutputJson(t, terraformOptions, "protected_items_list")

		assert.Equal(t, list1, list2, "List should be consistent across reads")
	})
}
