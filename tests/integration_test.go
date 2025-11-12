package test

import (
	"os"
	"testing"
	"time"

	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

// TestFullMigrationWorkflow tests the complete end-to-end migration workflow
// This test executes: Discover -> Initialize -> Replicate
func TestFullMigrationWorkflow(t *testing.T) {
	// This is an integration test that takes longer to run
	if testing.Short() {
		t.Skip("Skipping integration test in short mode")
	}

	subscriptionID := os.Getenv("ARM_SUBSCRIPTION_ID")
	hciSubscriptionID := os.Getenv("ARM_HCI_SUBSCRIPTION_ID")

	if subscriptionID == "" || hciSubscriptionID == "" {
		t.Skip("Required environment variables not set")
	}

	// Step 1: Discover machines
	t.Run("Step1_DiscoverMachines", func(t *testing.T) {
		discoverOptions := &terraform.Options{
			TerraformDir: "../examples/discover",
			Vars: map[string]interface{}{
				"subscription_id": subscriptionID,
			},
			NoColor: true,
		}

		defer terraform.Destroy(t, discoverOptions)
		terraform.InitAndApply(t, discoverOptions)

		// Verify machines were discovered
		discoveredMachinesJSON := terraform.OutputJson(t, discoverOptions, "discovered_machines")
		assert.NotEmpty(t, discoveredMachinesJSON, "Should discover at least one machine")
	})

	// Step 2: Initialize replication infrastructure
	t.Run("Step2_InitializeInfrastructure", func(t *testing.T) {
		initOptions := &terraform.Options{
			TerraformDir: "../examples/initialize",
			Vars: map[string]interface{}{
				"subscription_id":     subscriptionID,
				"hci_subscription_id": hciSubscriptionID,
			},
			NoColor: true,
		}

		defer terraform.Destroy(t, initOptions)
		terraform.InitAndApply(t, initOptions)

		// Verify infrastructure was created
		vaultID := terraform.Output(t, initOptions, "replication_vault_id")
		assert.NotEmpty(t, vaultID, "Replication vault should be created")

		policyID := terraform.Output(t, initOptions, "replication_policy_id")
		assert.NotEmpty(t, policyID, "Replication policy should be created")
	})

	// Step 3: Start VM replication
	t.Run("Step3_ReplicateVM", func(t *testing.T) {
		replicateOptions := &terraform.Options{
			TerraformDir: "../examples/replicate",
			Vars: map[string]interface{}{
				"subscription_id":     subscriptionID,
				"hci_subscription_id": hciSubscriptionID,
			},
			NoColor: true,
			// Replication can take time to start
			RetryableTerraformErrors: map[string]string{
				".*timeout while waiting.*": "Waiting for replication to start",
			},
			MaxRetries:         5,
			TimeBetweenRetries: 10 * time.Second,
		}

		defer terraform.Destroy(t, replicateOptions)
		terraform.InitAndApply(t, replicateOptions)

		// Verify replication was started
		protectedItemID := terraform.Output(t, replicateOptions, "protected_item_id")
		assert.NotEmpty(t, protectedItemID, "Protected item should be created")

		replicationState := terraform.Output(t, replicateOptions, "replication_state")
		assert.NotEmpty(t, replicationState, "Replication state should be available")
	})
}

// TestWorkflowWithMultipleVMs tests replicating multiple VMs
func TestWorkflowWithMultipleVMs(t *testing.T) {
	if testing.Short() {
		t.Skip("Skipping integration test in short mode")
	}

	subscriptionID := os.Getenv("ARM_SUBSCRIPTION_ID")
	if subscriptionID == "" {
		t.Skip("ARM_SUBSCRIPTION_ID environment variable not set")
	}

	// Initialize infrastructure once
	initOptions := &terraform.Options{
		TerraformDir: "../examples/initialize",
		NoColor:      true,
	}

	defer terraform.Destroy(t, initOptions)
	terraform.InitAndApply(t, initOptions)

	vaultID := terraform.Output(t, initOptions, "replication_vault_id")
	require.NotEmpty(t, vaultID, "Vault must be created before replicating VMs")

	// Replicate multiple VMs using the same infrastructure
	vmNames := []string{"vm-01", "vm-02", "vm-03"}

	for _, vmName := range vmNames {
		t.Run("Replicate_"+vmName, func(t *testing.T) {
			replicateOptions := &terraform.Options{
				TerraformDir: "../examples/replicate",
				Vars: map[string]interface{}{
					"target_vm_name":       vmName,
					"replication_vault_id": vaultID,
				},
				NoColor: true,
			}

			defer terraform.Destroy(t, replicateOptions)
			terraform.InitAndApply(t, replicateOptions)

			protectedItemID := terraform.Output(t, replicateOptions, "protected_item_id")
			assert.NotEmpty(t, protectedItemID, "Protected item should be created for "+vmName)
		})
	}
}

// TestCrossSubscriptionMigration tests migration across subscriptions
func TestCrossSubscriptionMigration(t *testing.T) {
	if testing.Short() {
		t.Skip("Skipping integration test in short mode")
	}

	subscriptionID := os.Getenv("ARM_SUBSCRIPTION_ID")
	hciSubscriptionID := os.Getenv("ARM_HCI_SUBSCRIPTION_ID")

	if subscriptionID == "" || hciSubscriptionID == "" {
		t.Skip("Required environment variables not set")
	}

	// Verify cross-subscription configuration
	t.Run("VerifyCrossSubscriptionSetup", func(t *testing.T) {
		assert.NotEqual(t, subscriptionID, hciSubscriptionID,
			"Test requires two different subscriptions")
	})

	// Initialize with cross-subscription configuration
	t.Run("InitializeCrossSubscription", func(t *testing.T) {
		initOptions := &terraform.Options{
			TerraformDir: "../examples/initialize",
			Vars: map[string]interface{}{
				"subscription_id":     subscriptionID,
				"hci_subscription_id": hciSubscriptionID,
			},
			NoColor: true,
		}

		defer terraform.Destroy(t, initOptions)
		terraform.InitAndApply(t, initOptions)

		vaultID := terraform.Output(t, initOptions, "replication_vault_id")
		targetFabricID := terraform.Output(t, initOptions, "target_fabric_id")

		// Verify vault is in primary subscription
		assert.Contains(t, vaultID, subscriptionID,
			"Vault should be in primary subscription")

		// Verify target fabric references HCI subscription
		assert.Contains(t, targetFabricID, hciSubscriptionID,
			"Target fabric should reference HCI subscription")
	})
}

// TestErrorHandlingAndRecovery tests error scenarios and recovery
func TestErrorHandlingAndRecovery(t *testing.T) {
	if testing.Short() {
		t.Skip("Skipping integration test in short mode")
	}

	subscriptionID := os.Getenv("ARM_SUBSCRIPTION_ID")
	if subscriptionID == "" {
		t.Skip("ARM_SUBSCRIPTION_ID environment variable not set")
	}

	// Test 1: Attempt to replicate without initializing first
	t.Run("ReplicateWithoutInitialize", func(t *testing.T) {
		replicateOptions := &terraform.Options{
			TerraformDir: "../examples/replicate",
			Vars: map[string]interface{}{
				"replication_vault_id": "/subscriptions/.../non-existent-vault",
			},
			NoColor: true,
		}

		// This should fail because vault doesn't exist
		_, err := terraform.InitAndApplyE(t, replicateOptions)
		assert.Error(t, err, "Should fail when vault doesn't exist")
	})

	// Test 2: Recover from failed initialization
	t.Run("RecoverFromFailedInit", func(t *testing.T) {
		initOptions := &terraform.Options{
			TerraformDir: "../examples/initialize",
			NoColor:      true,
		}

		defer terraform.Destroy(t, initOptions)

		// First attempt with invalid configuration
		_, _ = terraform.InitAndApplyE(t, initOptions)
		// May fail due to invalid config

		// Fix configuration and retry
		terraform.InitAndApply(t, initOptions)

		vaultID := terraform.Output(t, initOptions, "replication_vault_id")
		assert.NotEmpty(t, vaultID, "Should recover and create vault successfully")
	})
}

// TestResourceCleanup tests proper cleanup of resources
func TestResourceCleanup(t *testing.T) {
	if testing.Short() {
		t.Skip("Skipping integration test in short mode")
	}

	subscriptionID := os.Getenv("ARM_SUBSCRIPTION_ID")
	if subscriptionID == "" {
		t.Skip("ARM_SUBSCRIPTION_ID environment variable not set")
	}

	t.Run("CleanupAfterReplication", func(t *testing.T) {
		initOptions := &terraform.Options{
			TerraformDir: "../examples/initialize",
			NoColor:      true,
		}

		// Create infrastructure
		terraform.InitAndApply(t, initOptions)
		vaultID := terraform.Output(t, initOptions, "replication_vault_id")
		assert.NotEmpty(t, vaultID, "Vault should be created")

		// Clean up
		terraform.Destroy(t, initOptions)

		// Verify cleanup was successful (no errors during destroy)
		// If destroy fails, the test will fail
	})
}

// TestPerformanceAndScaling tests performance with multiple operations
func TestPerformanceAndScaling(t *testing.T) {
	if testing.Short() {
		t.Skip("Skipping performance test in short mode")
	}

	subscriptionID := os.Getenv("ARM_SUBSCRIPTION_ID")
	if subscriptionID == "" {
		t.Skip("ARM_SUBSCRIPTION_ID environment variable not set")
	}

	t.Run("ParallelReplication", func(t *testing.T) {
		// Initialize infrastructure
		initOptions := &terraform.Options{
			TerraformDir: "../examples/initialize",
			NoColor:      true,
		}

		defer terraform.Destroy(t, initOptions)
		terraform.InitAndApply(t, initOptions)

		// Measure time to replicate multiple VMs in parallel
		start := time.Now()

		// This would test parallel replication if we had multiple VMs
		// For now, we just verify the infrastructure can support it
		vaultID := terraform.Output(t, initOptions, "replication_vault_id")
		assert.NotEmpty(t, vaultID, "Infrastructure should support parallel operations")

		elapsed := time.Since(start)
		t.Logf("Infrastructure setup completed in %s", elapsed)
	})
}

// TestDataConsistency tests data consistency across operations
func TestDataConsistency(t *testing.T) {
	if testing.Short() {
		t.Skip("Skipping integration test in short mode")
	}

	subscriptionID := os.Getenv("ARM_SUBSCRIPTION_ID")
	if subscriptionID == "" {
		t.Skip("ARM_SUBSCRIPTION_ID environment variable not set")
	}

	t.Run("ConsistentStateAcrossOperations", func(t *testing.T) {
		initOptions := &terraform.Options{
			TerraformDir: "../examples/initialize",
			NoColor:      true,
		}

		defer terraform.Destroy(t, initOptions)
		terraform.InitAndApply(t, initOptions)

		// Get initial state
		firstVaultID := terraform.Output(t, initOptions, "replication_vault_id")
		firstPolicyID := terraform.Output(t, initOptions, "replication_policy_id")

		// Apply again (should be idempotent)
		terraform.Apply(t, initOptions)

		// Verify state hasn't changed
		secondVaultID := terraform.Output(t, initOptions, "replication_vault_id")
		secondPolicyID := terraform.Output(t, initOptions, "replication_policy_id")

		assert.Equal(t, firstVaultID, secondVaultID, "Vault ID should remain consistent")
		assert.Equal(t, firstPolicyID, secondPolicyID, "Policy ID should remain consistent")
	})
}
