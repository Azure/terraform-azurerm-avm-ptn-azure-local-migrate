package test

import (
	"encoding/json"
	"fmt"
	"os"
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

// TestDiscoverCommand tests the discover operation mode
func TestDiscoverCommand(t *testing.T) {
	t.Parallel()

	// Get required environment variables
	subscriptionID := os.Getenv("ARM_SUBSCRIPTION_ID")
	if subscriptionID == "" {
		t.Skip("ARM_SUBSCRIPTION_ID environment variable not set")
	}

	// Terraform options for discover mode
	terraformOptions := &terraform.Options{
		TerraformDir: "../examples/discover",
		Vars: map[string]interface{}{
			"subscription_id": subscriptionID,
		},
		NoColor: true,
	}

	// Cleanup after test
	defer terraform.Destroy(t, terraformOptions)

	// Run terraform init and apply
	terraform.InitAndApply(t, terraformOptions)

	// Test 1: Verify discovered_machines output exists and is not empty
	t.Run("VerifyDiscoveredMachinesOutput", func(t *testing.T) {
		discoveredMachinesJSON := terraform.OutputJson(t, terraformOptions, "discovered_machines")

		var discoveredMachines []map[string]interface{}
		err := json.Unmarshal([]byte(discoveredMachinesJSON), &discoveredMachines)
		require.NoError(t, err, "Failed to parse discovered_machines output")

		// Verify we have at least one discovered machine
		assert.Greater(t, len(discoveredMachines), 0, "Expected at least one discovered machine")
	})

	// Test 2: Verify machine properties structure
	t.Run("VerifyMachineProperties", func(t *testing.T) {
		discoveredMachinesJSON := terraform.OutputJson(t, terraformOptions, "discovered_machines")

		var discoveredMachines []map[string]interface{}
		err := json.Unmarshal([]byte(discoveredMachinesJSON), &discoveredMachines)
		require.NoError(t, err)

		if len(discoveredMachines) > 0 {
			machine := discoveredMachines[0]

			// Verify required properties exist
			assert.Contains(t, machine, "id", "Machine should have an id property")
			assert.Contains(t, machine, "name", "Machine should have a name property")
			assert.Contains(t, machine, "properties", "Machine should have properties")

			// Verify properties structure
			properties, ok := machine["properties"].(map[string]interface{})
			assert.True(t, ok, "Properties should be a map")
			assert.Contains(t, properties, "discoveryData", "Properties should contain discoveryData")
		}
	})

	// Test 3: Verify filtered output (if available)
	t.Run("VerifyFilteredOutput", func(t *testing.T) {
		// Check if filtered_discovered_machines output exists
		outputs := terraform.OutputAll(t, terraformOptions)
		if _, exists := outputs["filtered_discovered_machines"]; exists {
			filteredMachinesJSON := terraform.OutputJson(t, terraformOptions, "filtered_discovered_machines")

			var filteredMachines []map[string]interface{}
			err := json.Unmarshal([]byte(filteredMachinesJSON), &filteredMachines)
			require.NoError(t, err, "Failed to parse filtered_discovered_machines output")

			if len(filteredMachines) > 0 {
				machine := filteredMachines[0]

				// Verify expected filtered fields
				expectedFields := []string{"index", "machine_name", "ip_address", "os_name", "boot_type", "os_disk_id"}
				for _, field := range expectedFields {
					assert.Contains(t, machine, field, fmt.Sprintf("Filtered machine should have %s field", field))
				}
			}
		}
	})

	// Test 4: Verify discovery data contains required information
	t.Run("VerifyDiscoveryData", func(t *testing.T) {
		discoveredMachinesJSON := terraform.OutputJson(t, terraformOptions, "discovered_machines")

		var discoveredMachines []map[string]interface{}
		err := json.Unmarshal([]byte(discoveredMachinesJSON), &discoveredMachines)
		require.NoError(t, err)

		if len(discoveredMachines) > 0 {
			machine := discoveredMachines[0]
			properties, _ := machine["properties"].(map[string]interface{})
			discoveryDataArray, _ := properties["discoveryData"].([]interface{})

			if len(discoveryDataArray) > 0 {
				discoveryData := discoveryDataArray[0].(map[string]interface{})

				// Verify common discovery data fields
				assert.Contains(t, discoveryData, "machineId", "Discovery data should contain machineId")
				assert.Contains(t, discoveryData, "machineName", "Discovery data should contain machineName")
				assert.Contains(t, discoveryData, "osType", "Discovery data should contain osType")
			}
		}
	})
}

// TestDiscoverCommandValidation tests input validation for discover mode
func TestDiscoverCommandValidation(t *testing.T) {
	t.Parallel()

	tests := []struct {
		name          string
		vars          map[string]interface{}
		expectedError bool
		description   string
	}{
		{
			name: "MissingResourceGroup",
			vars: map[string]interface{}{
				"operation_mode": "discover",
				"location":       "eastus",
			},
			expectedError: true,
			description:   "Should fail when resource_group_name is not provided",
		},
		{
			name: "InvalidOperationMode",
			vars: map[string]interface{}{
				"operation_mode":      "invalid",
				"resource_group_name": "test-rg",
				"location":            "eastus",
			},
			expectedError: true,
			description:   "Should fail with invalid operation_mode",
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

// TestDiscoverCommandOutputFormats tests different output formats
func TestDiscoverCommandOutputFormats(t *testing.T) {
	t.Parallel()

	subscriptionID := os.Getenv("ARM_SUBSCRIPTION_ID")
	if subscriptionID == "" {
		t.Skip("ARM_SUBSCRIPTION_ID environment variable not set")
	}

	terraformOptions := &terraform.Options{
		TerraformDir: "../examples/discover",
		Vars: map[string]interface{}{
			"subscription_id": subscriptionID,
		},
		NoColor: true,
	}

	defer terraform.Destroy(t, terraformOptions)
	terraform.InitAndApply(t, terraformOptions)

	// Test that output can be parsed as valid JSON
	t.Run("ValidJSONOutput", func(t *testing.T) {
		output := terraform.OutputJson(t, terraformOptions, "discovered_machines")
		assert.True(t, json.Valid([]byte(output)), "Output should be valid JSON")
	})

	// Test output structure matches expected schema
	t.Run("OutputSchemaValidation", func(t *testing.T) {
		discoveredMachinesJSON := terraform.OutputJson(t, terraformOptions, "discovered_machines")

		var machines []map[string]interface{}
		err := json.Unmarshal([]byte(discoveredMachinesJSON), &machines)
		require.NoError(t, err)

		// Verify each machine has expected top-level structure
		for _, machine := range machines {
			assert.NotEmpty(t, machine["id"], "Each machine should have an ID")
			assert.NotEmpty(t, machine["name"], "Each machine should have a name")
			assert.NotEmpty(t, machine["type"], "Each machine should have a type")
			assert.Equal(t, "Microsoft.Migrate/MigrateProjects/Machines", machine["type"], "Type should match expected value")
		}
	})
}
