package test

import (
	"fmt"
	"os"
	"strings"
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

// TestInitializeCommand tests the initialize operation mode
func TestInitializeCommand(t *testing.T) {
	t.Parallel()

	// Get required environment variables
	subscriptionID := os.Getenv("ARM_SUBSCRIPTION_ID")
	hciSubscriptionID := os.Getenv("ARM_HCI_SUBSCRIPTION_ID")

	if subscriptionID == "" || hciSubscriptionID == "" {
		t.Skip("Required environment variables not set (ARM_SUBSCRIPTION_ID, ARM_HCI_SUBSCRIPTION_ID)")
	}

	// Terraform options for initialize mode
	terraformOptions := &terraform.Options{
		TerraformDir: "../examples/initialize",
		Vars: map[string]interface{}{
			"subscription_id":     subscriptionID,
			"hci_subscription_id": hciSubscriptionID,
		},
		NoColor: true,
	}

	// Cleanup after test
	defer terraform.Destroy(t, terraformOptions)

	// Run terraform init and apply
	terraform.InitAndApply(t, terraformOptions)

	// Test 1: Verify replication vault was created
	t.Run("VerifyReplicationVault", func(t *testing.T) {
		vaultID := terraform.Output(t, terraformOptions, "replication_vault_id")

		assert.NotEmpty(t, vaultID, "Replication vault ID should not be empty")
		assert.Contains(t, vaultID, "Microsoft.DataReplication/replicationVaults",
			"Vault ID should contain correct resource type")
		assert.Contains(t, vaultID, subscriptionID,
			"Vault ID should contain subscription ID")
	})

	// Test 2: Verify storage account was created
	t.Run("VerifyStorageAccount", func(t *testing.T) {
		storageID := terraform.Output(t, terraformOptions, "storage_account_id")

		assert.NotEmpty(t, storageID, "Storage account ID should not be empty")
		assert.Contains(t, storageID, "Microsoft.Storage/storageAccounts",
			"Storage ID should contain correct resource type")
	})

	// Test 3: Verify replication policy was created
	t.Run("VerifyReplicationPolicy", func(t *testing.T) {
		policyID := terraform.Output(t, terraformOptions, "replication_policy_id")

		assert.NotEmpty(t, policyID, "Replication policy ID should not be empty")
		assert.Contains(t, policyID, "replicationPolicies",
			"Policy ID should contain correct resource type")
	})

	// Test 4: Verify source fabric configuration
	t.Run("VerifySourceFabric", func(t *testing.T) {
		sourceFabricID := terraform.Output(t, terraformOptions, "source_fabric_id")

		assert.NotEmpty(t, sourceFabricID, "Source fabric ID should not be empty")
		assert.Contains(t, sourceFabricID, "replicationFabrics",
			"Source fabric ID should contain correct resource type")
	})

	// Test 5: Verify target fabric configuration
	t.Run("VerifyTargetFabric", func(t *testing.T) {
		targetFabricID := terraform.Output(t, terraformOptions, "target_fabric_id")

		assert.NotEmpty(t, targetFabricID, "Target fabric ID should not be empty")
		assert.Contains(t, targetFabricID, "replicationFabrics",
			"Target fabric ID should contain correct resource type")
	})

	// Test 6: Verify DRA (Dra Replication Agent) configuration
	t.Run("VerifyDRAConfiguration", func(t *testing.T) {
		draID := terraform.Output(t, terraformOptions, "source_dra_id")

		assert.NotEmpty(t, draID, "Source DRA ID should not be empty")
		assert.Contains(t, draID, "dras", "DRA ID should contain correct resource type")
	})

	// Test 7: Verify replication extension was created
	t.Run("VerifyReplicationExtension", func(t *testing.T) {
		extensionID := terraform.Output(t, terraformOptions, "replication_extension_id")

		assert.NotEmpty(t, extensionID, "Replication extension ID should not be empty")
		assert.Contains(t, extensionID, "replicationExtensions",
			"Extension ID should contain correct resource type")
	})

	// Test 8: Verify cross-subscription configuration
	t.Run("VerifyCrossSubscriptionSetup", func(t *testing.T) {
		vaultID := terraform.Output(t, terraformOptions, "replication_vault_id")
		targetFabricID := terraform.Output(t, terraformOptions, "target_fabric_id")

		// Vault should be in primary subscription
		assert.Contains(t, vaultID, subscriptionID,
			"Vault should be in primary subscription")

		// Target fabric should reference HCI subscription
		assert.Contains(t, targetFabricID, hciSubscriptionID,
			"Target fabric should reference HCI subscription")
	})
}

// TestInitializeCommandResourceCreation tests that all required resources are created
func TestInitializeCommandResourceCreation(t *testing.T) {
	t.Parallel()

	subscriptionID := os.Getenv("ARM_SUBSCRIPTION_ID")
	if subscriptionID == "" {
		t.Skip("ARM_SUBSCRIPTION_ID environment variable not set")
	}

	terraformOptions := &terraform.Options{
		TerraformDir: "../examples/initialize",
		NoColor:      true,
	}

	defer terraform.Destroy(t, terraformOptions)
	terraform.InitAndApply(t, terraformOptions)

	// Test that all expected outputs exist
	t.Run("VerifyAllOutputsExist", func(t *testing.T) {
		outputs := terraform.OutputAll(t, terraformOptions)

		expectedOutputs := []string{
			"replication_vault_id",
			"storage_account_id",
			"replication_policy_id",
			"source_fabric_id",
			"target_fabric_id",
			"source_dra_id",
			"target_dra_id",
			"replication_extension_id",
		}

		for _, output := range expectedOutputs {
			assert.Contains(t, outputs, output,
				fmt.Sprintf("Expected output '%s' should exist", output))
		}
	})
}

// TestInitializeCommandIdempotency tests that running initialize multiple times is idempotent
func TestInitializeCommandIdempotency(t *testing.T) {
	t.Parallel()

	subscriptionID := os.Getenv("ARM_SUBSCRIPTION_ID")
	if subscriptionID == "" {
		t.Skip("ARM_SUBSCRIPTION_ID environment variable not set")
	}

	terraformOptions := &terraform.Options{
		TerraformDir: "../examples/initialize",
		NoColor:      true,
	}

	defer terraform.Destroy(t, terraformOptions)

	// First apply
	terraform.InitAndApply(t, terraformOptions)
	firstVaultID := terraform.Output(t, terraformOptions, "replication_vault_id")

	// Second apply (should be idempotent - no changes)
	terraform.Apply(t, terraformOptions)
	secondVaultID := terraform.Output(t, terraformOptions, "replication_vault_id")

	// Verify the vault ID hasn't changed
	assert.Equal(t, firstVaultID, secondVaultID,
		"Vault ID should remain the same on subsequent applies")
}

// TestInitializeCommandNaming tests resource naming conventions
func TestInitializeCommandNaming(t *testing.T) {
	t.Parallel()

	subscriptionID := os.Getenv("ARM_SUBSCRIPTION_ID")
	if subscriptionID == "" {
		t.Skip("ARM_SUBSCRIPTION_ID environment variable not set")
	}

	terraformOptions := &terraform.Options{
		TerraformDir: "../examples/initialize",
		Vars: map[string]interface{}{
			"name_prefix": "test",
		},
		NoColor: true,
	}

	defer terraform.Destroy(t, terraformOptions)
	terraform.InitAndApply(t, terraformOptions)

	// Test resource naming follows conventions
	t.Run("VerifyNamingConventions", func(t *testing.T) {
		vaultID := terraform.Output(t, terraformOptions, "replication_vault_id")

		// Extract resource name from ID
		parts := strings.Split(vaultID, "/")
		resourceName := parts[len(parts)-1]

		// Verify naming pattern
		assert.NotEmpty(t, resourceName, "Resource name should not be empty")
		assert.True(t, len(resourceName) <= 80,
			"Resource name should not exceed Azure naming limits")
	})
}

// TestInitializeCommandPolicyConfiguration tests replication policy settings
func TestInitializeCommandPolicyConfiguration(t *testing.T) {
	t.Parallel()

	subscriptionID := os.Getenv("ARM_SUBSCRIPTION_ID")
	if subscriptionID == "" {
		t.Skip("ARM_SUBSCRIPTION_ID environment variable not set")
	}

	terraformOptions := &terraform.Options{
		TerraformDir: "../examples/initialize",
		Vars: map[string]interface{}{
			"crash_consistent_frequency_in_minutes": 5,
			"app_consistent_frequency_in_minutes":   60,
			"recovery_point_history_in_minutes":     1440,
		},
		NoColor: true,
	}

	defer terraform.Destroy(t, terraformOptions)
	terraform.InitAndApply(t, terraformOptions)

	// Test that policy was created with custom settings
	t.Run("VerifyCustomPolicySettings", func(t *testing.T) {
		policyID := terraform.Output(t, terraformOptions, "replication_policy_id")
		assert.NotEmpty(t, policyID, "Policy should be created with custom settings")
	})
}

// TestInitializeCommandFabricTypes tests different fabric type combinations
func TestInitializeCommandFabricTypes(t *testing.T) {
	t.Parallel()

	subscriptionID := os.Getenv("ARM_SUBSCRIPTION_ID")
	if subscriptionID == "" {
		t.Skip("ARM_SUBSCRIPTION_ID environment variable not set")
	}

	testCases := []struct {
		name             string
		sourceType       string
		targetType       string
		expectedInSource string
		expectedInTarget string
	}{
		{
			name:             "VMwareToAzStackHCI",
			sourceType:       "VMware",
			targetType:       "AzStackHCI",
			expectedInSource: "VMware",
			expectedInTarget: "AzStackHCI",
		},
		{
			name:             "HyperVToAzStackHCI",
			sourceType:       "HyperV",
			targetType:       "AzStackHCI",
			expectedInSource: "HyperV",
			expectedInTarget: "AzStackHCI",
		},
	}

	for _, tc := range testCases {
		t.Run(tc.name, func(t *testing.T) {
			terraformOptions := &terraform.Options{
				TerraformDir: "../examples/initialize",
				Vars: map[string]interface{}{
					"source_fabric_type": tc.sourceType,
					"target_fabric_type": tc.targetType,
				},
				NoColor: true,
			}

			defer terraform.Destroy(t, terraformOptions)
			terraform.InitAndApply(t, terraformOptions)

			sourceFabricID := terraform.Output(t, terraformOptions, "source_fabric_id")
			targetFabricID := terraform.Output(t, terraformOptions, "target_fabric_id")

			assert.NotEmpty(t, sourceFabricID, "Source fabric should be created")
			assert.NotEmpty(t, targetFabricID, "Target fabric should be created")
		})
	}
}

// TestInitializeCommandVaultCreation tests vault creation scenarios
func TestInitializeCommandVaultCreation(t *testing.T) {
	t.Parallel()

	subscriptionID := os.Getenv("ARM_SUBSCRIPTION_ID")
	if subscriptionID == "" {
		t.Skip("ARM_SUBSCRIPTION_ID environment variable not set")
	}

	t.Run("CreateNewVault", func(t *testing.T) {
		terraformOptions := &terraform.Options{
			TerraformDir: "../examples/initialize",
			Vars: map[string]interface{}{
				"create_vault": true,
			},
			NoColor: true,
		}

		defer terraform.Destroy(t, terraformOptions)
		terraform.InitAndApply(t, terraformOptions)

		vaultID := terraform.Output(t, terraformOptions, "replication_vault_id")
		assert.NotEmpty(t, vaultID, "New vault should be created")
	})
}
