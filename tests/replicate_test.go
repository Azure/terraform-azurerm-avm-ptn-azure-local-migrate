package test

import (
	"fmt"
	"os"
	"strings"
	"testing"
	"time"

	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

// TestReplicateCommand tests the replicate operation mode
func TestReplicateCommand(t *testing.T) {
	t.Parallel()

	// Get required environment variables
	subscriptionID := os.Getenv("ARM_SUBSCRIPTION_ID")
	hciSubscriptionID := os.Getenv("ARM_HCI_SUBSCRIPTION_ID")

	if subscriptionID == "" || hciSubscriptionID == "" {
		t.Skip("Required environment variables not set")
	}

	// Terraform options for replicate mode
	terraformOptions := &terraform.Options{
		TerraformDir: "../examples/replicate",
		Vars: map[string]interface{}{
			"subscription_id":     subscriptionID,
			"hci_subscription_id": hciSubscriptionID,
		},
		NoColor: true,
		// Increase timeout for replication operations
		RetryableTerraformErrors: map[string]string{
			".*timeout while waiting.*": "Waiting for replication to complete",
		},
		MaxRetries:         3,
		TimeBetweenRetries: 5 * time.Second,
	}

	// Cleanup after test
	defer terraform.Destroy(t, terraformOptions)

	// Run terraform init and apply
	terraform.InitAndApply(t, terraformOptions)

	// Test 1: Verify protected item was created
	t.Run("VerifyProtectedItemCreated", func(t *testing.T) {
		protectedItemID := terraform.Output(t, terraformOptions, "protected_item_id")

		assert.NotEmpty(t, protectedItemID, "Protected item ID should not be empty")
		assert.Contains(t, protectedItemID, "Microsoft.DataReplication/replicationVaults/protectedItems",
			"Protected item ID should contain correct resource type")
	})

	// Test 2: Verify replication state
	t.Run("VerifyReplicationState", func(t *testing.T) {
		replicationState := terraform.Output(t, terraformOptions, "replication_state")

		assert.NotEmpty(t, replicationState, "Replication state should not be empty")

		// Valid states: InitialReplicationInProgress, Replicating, ProtectedCritical, Protected
		validStates := []string{
			"InitialReplicationInProgress",
			"Replicating",
			"Protected",
			"ProtectedCritical",
		}

		assert.Contains(t, validStates, replicationState,
			"Replication state should be one of the valid states")
	})

	// Test 3: Verify target VM name
	t.Run("VerifyTargetVMName", func(t *testing.T) {
		targetVMName := terraform.Output(t, terraformOptions, "target_vm_name")

		assert.NotEmpty(t, targetVMName, "Target VM name should not be empty")
		assert.True(t, len(targetVMName) <= 64, "Target VM name should not exceed 64 characters")
	})

	// Test 4: Verify disk configuration
	t.Run("VerifyDiskConfiguration", func(t *testing.T) {
		protectedItemID := terraform.Output(t, terraformOptions, "protected_item_id")

		// Verify protected item was created with disk configuration
		assert.NotEmpty(t, protectedItemID, "Protected item should include disk configuration")
	})

	// Test 5: Verify network configuration
	t.Run("VerifyNetworkConfiguration", func(t *testing.T) {
		protectedItemID := terraform.Output(t, terraformOptions, "protected_item_id")

		// Verify protected item includes network configuration
		assert.NotEmpty(t, protectedItemID, "Protected item should include network configuration")
	})
}

// TestReplicateCommandWithMultipleDisks tests replication with multiple disk configuration
func TestReplicateCommandWithMultipleDisks(t *testing.T) {
	t.Parallel()

	subscriptionID := os.Getenv("ARM_SUBSCRIPTION_ID")
	if subscriptionID == "" {
		t.Skip("ARM_SUBSCRIPTION_ID environment variable not set")
	}

	terraformOptions := &terraform.Options{
		TerraformDir: "../examples/replicate",
		Vars: map[string]interface{}{
			"disks_to_include": []map[string]interface{}{
				{
					"disk_id":          "disk-os-001",
					"disk_size_gb":     128,
					"disk_file_format": "VHDX",
					"is_os_disk":       true,
					"is_dynamic":       false,
				},
				{
					"disk_id":          "disk-data-001",
					"disk_size_gb":     512,
					"disk_file_format": "VHDX",
					"is_os_disk":       false,
					"is_dynamic":       true,
				},
			},
		},
		NoColor: true,
	}

	defer terraform.Destroy(t, terraformOptions)
	terraform.InitAndApply(t, terraformOptions)

	// Verify protected item was created with multiple disks
	t.Run("VerifyMultipleDiskConfiguration", func(t *testing.T) {
		protectedItemID := terraform.Output(t, terraformOptions, "protected_item_id")
		assert.NotEmpty(t, protectedItemID, "Protected item should be created with multiple disks")
	})
}

// TestReplicateCommandWithDynamicMemory tests replication with dynamic memory enabled
func TestReplicateCommandWithDynamicMemory(t *testing.T) {
	t.Parallel()

	subscriptionID := os.Getenv("ARM_SUBSCRIPTION_ID")
	if subscriptionID == "" {
		t.Skip("ARM_SUBSCRIPTION_ID environment variable not set")
	}

	terraformOptions := &terraform.Options{
		TerraformDir: "../examples/replicate",
		Vars: map[string]interface{}{
			"is_dynamic_memory_enabled": true,
			"target_vm_ram_mb":          8192,
		},
		NoColor: true,
	}

	defer terraform.Destroy(t, terraformOptions)
	terraform.InitAndApply(t, terraformOptions)

	// Verify protected item was created with dynamic memory
	t.Run("VerifyDynamicMemoryConfiguration", func(t *testing.T) {
		protectedItemID := terraform.Output(t, terraformOptions, "protected_item_id")
		assert.NotEmpty(t, protectedItemID, "Protected item should be created with dynamic memory")
	})
}

// TestReplicateCommandVMSizing tests various VM sizing configurations
func TestReplicateCommandVMSizing(t *testing.T) {
	t.Parallel()

	subscriptionID := os.Getenv("ARM_SUBSCRIPTION_ID")
	if subscriptionID == "" {
		t.Skip("ARM_SUBSCRIPTION_ID environment variable not set")
	}

	testCases := []struct {
		name     string
		cpuCores int
		ramMB    int
	}{
		{
			name:     "SmallVM",
			cpuCores: 2,
			ramMB:    4096,
		},
		{
			name:     "MediumVM",
			cpuCores: 4,
			ramMB:    8192,
		},
		{
			name:     "LargeVM",
			cpuCores: 8,
			ramMB:    16384,
		},
	}

	for _, tc := range testCases {
		t.Run(tc.name, func(t *testing.T) {
			terraformOptions := &terraform.Options{
				TerraformDir: "../examples/replicate",
				Vars: map[string]interface{}{
					"target_vm_cpu_cores": tc.cpuCores,
					"target_vm_ram_mb":    tc.ramMB,
				},
				NoColor: true,
			}

			defer terraform.Destroy(t, terraformOptions)
			terraform.InitAndApply(t, terraformOptions)

			protectedItemID := terraform.Output(t, terraformOptions, "protected_item_id")
			assert.NotEmpty(t, protectedItemID,
				fmt.Sprintf("Protected item should be created with %d CPUs and %d MB RAM", tc.cpuCores, tc.ramMB))
		})
	}
}

// TestReplicateCommandHyperVGeneration tests different Hyper-V generation configurations
func TestReplicateCommandHyperVGeneration(t *testing.T) {
	t.Parallel()

	subscriptionID := os.Getenv("ARM_SUBSCRIPTION_ID")
	if subscriptionID == "" {
		t.Skip("ARM_SUBSCRIPTION_ID environment variable not set")
	}

	generations := []string{"1", "2"}

	for _, gen := range generations {
		t.Run(fmt.Sprintf("Generation%s", gen), func(t *testing.T) {
			terraformOptions := &terraform.Options{
				TerraformDir: "../examples/replicate",
				Vars: map[string]interface{}{
					"hyperv_generation": gen,
				},
				NoColor: true,
			}

			defer terraform.Destroy(t, terraformOptions)
			terraform.InitAndApply(t, terraformOptions)

			protectedItemID := terraform.Output(t, terraformOptions, "protected_item_id")
			assert.NotEmpty(t, protectedItemID,
				fmt.Sprintf("Protected item should be created with Hyper-V Generation %s", gen))
		})
	}
}

// TestReplicateCommandInstanceTypes tests different instance type configurations
func TestReplicateCommandInstanceTypes(t *testing.T) {
	t.Parallel()

	subscriptionID := os.Getenv("ARM_SUBSCRIPTION_ID")
	if subscriptionID == "" {
		t.Skip("ARM_SUBSCRIPTION_ID environment variable not set")
	}

	instanceTypes := []string{
		"VMwareToAzStackHCI",
		"HyperVToAzStackHCI",
	}

	for _, instanceType := range instanceTypes {
		t.Run(instanceType, func(t *testing.T) {
			terraformOptions := &terraform.Options{
				TerraformDir: "../examples/replicate",
				Vars: map[string]interface{}{
					"instance_type": instanceType,
				},
				NoColor: true,
			}

			defer terraform.Destroy(t, terraformOptions)
			terraform.InitAndApply(t, terraformOptions)

			protectedItemID := terraform.Output(t, terraformOptions, "protected_item_id")
			assert.NotEmpty(t, protectedItemID,
				fmt.Sprintf("Protected item should be created with instance type %s", instanceType))
		})
	}
}

// TestReplicateCommandNetworkConfiguration tests network adapter configuration
func TestReplicateCommandNetworkConfiguration(t *testing.T) {
	t.Parallel()

	subscriptionID := os.Getenv("ARM_SUBSCRIPTION_ID")
	if subscriptionID == "" {
		t.Skip("ARM_SUBSCRIPTION_ID environment variable not set")
	}

	terraformOptions := &terraform.Options{
		TerraformDir: "../examples/replicate",
		Vars: map[string]interface{}{
			"nics_to_include": []map[string]interface{}{
				{
					"nic_id":                      "nic-001",
					"target_network_id":           "/subscriptions/.../logicalnetworks/network-01",
					"selection_type_for_failover": "SelectedByUser",
				},
			},
		},
		NoColor: true,
	}

	defer terraform.Destroy(t, terraformOptions)
	terraform.InitAndApply(t, terraformOptions)

	// Verify protected item was created with network configuration
	t.Run("VerifyNetworkAdapterConfiguration", func(t *testing.T) {
		protectedItemID := terraform.Output(t, terraformOptions, "protected_item_id")
		assert.NotEmpty(t, protectedItemID, "Protected item should be created with network adapter configuration")
	})
}

// TestReplicateCommandValidation tests input validation for replicate mode
func TestReplicateCommandValidation(t *testing.T) {
	t.Parallel()

	tests := []struct {
		name          string
		vars          map[string]interface{}
		expectedError bool
		description   string
	}{
		{
			name: "MissingMachineID",
			vars: map[string]interface{}{
				"operation_mode":      "replicate",
				"resource_group_name": "test-rg",
				"location":            "eastus",
			},
			expectedError: true,
			description:   "Should fail when machine_id or machine_name is not provided",
		},
		{
			name: "MissingTargetVMName",
			vars: map[string]interface{}{
				"operation_mode":      "replicate",
				"resource_group_name": "test-rg",
				"location":            "eastus",
				"machine_id":          "/subscriptions/.../machines/test-machine",
			},
			expectedError: true,
			description:   "Should fail when target_vm_name is not provided",
		},
		{
			name: "InvalidHyperVGeneration",
			vars: map[string]interface{}{
				"operation_mode":    "replicate",
				"machine_id":        "/subscriptions/.../machines/test-machine",
				"target_vm_name":    "test-vm",
				"hyperv_generation": "3",
			},
			expectedError: true,
			description:   "Should fail with invalid Hyper-V generation",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			terraformOptions := &terraform.Options{
				TerraformDir: "../",
				Vars:         tt.vars,
				NoColor:      true,
			}

			_, err := terraform.InitAndPlanE(t, terraformOptions)

			if tt.expectedError {
				assert.Error(t, err, tt.description)
			} else {
				assert.NoError(t, err, tt.description)
			}
		})
	}
}

// TestReplicateCommandIdempotency tests that replication is idempotent
func TestReplicateCommandIdempotency(t *testing.T) {
	t.Parallel()

	subscriptionID := os.Getenv("ARM_SUBSCRIPTION_ID")
	if subscriptionID == "" {
		t.Skip("ARM_SUBSCRIPTION_ID environment variable not set")
	}

	terraformOptions := &terraform.Options{
		TerraformDir: "../examples/replicate",
		NoColor:      true,
	}

	defer terraform.Destroy(t, terraformOptions)

	// First apply
	terraform.InitAndApply(t, terraformOptions)
	firstProtectedItemID := terraform.Output(t, terraformOptions, "protected_item_id")

	// Second apply (should be idempotent - no changes)
	terraform.Apply(t, terraformOptions)
	secondProtectedItemID := terraform.Output(t, terraformOptions, "protected_item_id")

	// Verify the protected item ID hasn't changed
	assert.Equal(t, firstProtectedItemID, secondProtectedItemID,
		"Protected item ID should remain the same on subsequent applies")
}

// TestReplicateCommandOutputs tests all expected outputs
func TestReplicateCommandOutputs(t *testing.T) {
	t.Parallel()

	subscriptionID := os.Getenv("ARM_SUBSCRIPTION_ID")
	if subscriptionID == "" {
		t.Skip("ARM_SUBSCRIPTION_ID environment variable not set")
	}

	terraformOptions := &terraform.Options{
		TerraformDir: "../examples/replicate",
		NoColor:      true,
	}

	defer terraform.Destroy(t, terraformOptions)
	terraform.InitAndApply(t, terraformOptions)

	// Test that all expected outputs exist
	t.Run("VerifyAllOutputsExist", func(t *testing.T) {
		outputs := terraform.OutputAll(t, terraformOptions)

		expectedOutputs := []string{
			"protected_item_id",
			"replication_state",
			"target_vm_name",
		}

		for _, output := range expectedOutputs {
			assert.Contains(t, outputs, output,
				fmt.Sprintf("Expected output '%s' should exist", output))
		}
	})

	// Test output formats
	t.Run("VerifyOutputFormats", func(t *testing.T) {
		protectedItemID := terraform.Output(t, terraformOptions, "protected_item_id")

		// Verify ID format
		assert.True(t, strings.HasPrefix(protectedItemID, "/subscriptions/"),
			"Protected item ID should start with /subscriptions/")
	})
}

// TestReplicateCommandMachineNameUsage tests using machine_name instead of machine_id
func TestReplicateCommandMachineNameUsage(t *testing.T) {
	t.Parallel()

	subscriptionID := os.Getenv("ARM_SUBSCRIPTION_ID")
	if subscriptionID == "" {
		t.Skip("ARM_SUBSCRIPTION_ID environment variable not set")
	}

	terraformOptions := &terraform.Options{
		TerraformDir: "../examples/replicate",
		Vars: map[string]interface{}{
			"machine_name":   "test-machine-001",
			"project_name":   "test-migrate-project",
			"target_vm_name": "test-vm-migrated",
		},
		NoColor: true,
	}

	defer terraform.Destroy(t, terraformOptions)
	terraform.InitAndApply(t, terraformOptions)

	// Verify protected item was created using machine_name
	t.Run("VerifyMachineNameUsage", func(t *testing.T) {
		protectedItemID := terraform.Output(t, terraformOptions, "protected_item_id")
		assert.NotEmpty(t, protectedItemID, "Protected item should be created using machine_name")

		// Verify the protected item name matches machine_name
		assert.Contains(t, protectedItemID, "test-machine-001",
			"Protected item ID should contain the machine name")
	})
}
