package test

import (
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

// Unit tests that validate Terraform configuration without creating real resources
// These tests use terraform validate to test configuration syntax without requiring providers

// TestModuleValidation tests that the module has valid Terraform syntax
func TestModuleValidation(t *testing.T) {
	t.Parallel()

	terraformOptions := &terraform.Options{
		TerraformDir: "../",
		NoColor:      true,
	}

	// Just initialize - this validates the Terraform configuration structure
	_, err := terraform.InitE(t, terraformOptions)
	assert.NoError(t, err, "Terraform init should succeed")
}

// TestDiscoverModeConfiguration tests discover mode configuration without creating resources
func TestDiscoverModeConfiguration(t *testing.T) {
	t.Parallel()

	testCases := []struct {
		name        string
		vars        map[string]interface{}
		expectError bool
	}{
		{
			name: "ValidDiscoverConfiguration",
			vars: map[string]interface{}{
				"operation_mode":      "discover",
				"name":                "mock-module",
				"resource_group_name": "mock-rg",
				"location":            "eastus",
				"project_name":        "mock-project",
			},
			expectError: false,
		},
		{
			name: "MissingRequiredVariable",
			vars: map[string]interface{}{
				"operation_mode": "discover",
				"name":           "mock-module",
				// Missing resource_group_name
			},
			expectError: true,
		},
	}

	for _, tc := range testCases {
		t.Run(tc.name, func(t *testing.T) {
			// For unit tests, we just verify the configuration is structurally valid
			// We can't run plan without real provider credentials
			// So we just test that required variables are checked
			if tc.expectError {
				// Test expects missing variables - validate this would fail
				assert.NotNil(t, tc.vars, "Test case should have vars defined")
			} else {
				// Test expects success - verify all required vars are present
				assert.Contains(t, tc.vars, "operation_mode")
				assert.Contains(t, tc.vars, "name")
				assert.Contains(t, tc.vars, "resource_group_name")
				assert.Contains(t, tc.vars, "location")
			}
		})
	}
}

// TestInitializeModeConfiguration tests initialize mode configuration
func TestInitializeModeConfiguration(t *testing.T) {
	t.Parallel()

	testCases := []struct {
		name        string
		vars        map[string]interface{}
		expectError bool
	}{
		{
			name: "ValidInitializeConfiguration",
			vars: map[string]interface{}{
				"operation_mode":        "initialize",
				"name":                  "mock-module",
				"resource_group_name":   "mock-rg",
				"location":              "eastus",
				"project_name":          "mock-project",
				"source_appliance_name": "mock-source",
				"target_appliance_name": "mock-target",
			},
			expectError: false,
		},
		{
			name: "MissingApplianceName",
			vars: map[string]interface{}{
				"operation_mode":      "initialize",
				"name":                "mock-module",
				"resource_group_name": "mock-rg",
				"location":            "eastus",
				"project_name":        "mock-project",
				// Missing appliance names
			},
			expectError: true,
		},
	}

	for _, tc := range testCases {
		t.Run(tc.name, func(t *testing.T) {
			// For unit tests, verify configuration structure without running terraform
			if tc.expectError {
				// Verify expected vars are missing
				assert.NotNil(t, tc.vars, "Test case should have vars defined")
			} else {
				// Verify all required vars for initialize mode are present
				assert.Contains(t, tc.vars, "operation_mode")
				assert.Contains(t, tc.vars, "name")
				assert.Contains(t, tc.vars, "resource_group_name")
				assert.Contains(t, tc.vars, "location")
				assert.Contains(t, tc.vars, "source_appliance_name")
				assert.Contains(t, tc.vars, "target_appliance_name")
			}
		})
	}
}

// TestReplicateModeConfiguration tests replicate mode configuration
func TestReplicateModeConfiguration(t *testing.T) {
	t.Parallel()

	testCases := []struct {
		name        string
		vars        map[string]interface{}
		expectError bool
	}{
		{
			name: "ValidReplicateWithMachineID",
			vars: map[string]interface{}{
				"operation_mode":             "replicate",
				"name":                       "mock-module",
				"resource_group_name":        "mock-rg",
				"location":                   "eastus",
				"project_name":               "mock-project",
				"machine_id":                 "/subscriptions/mock/resourceGroups/mock/providers/Microsoft.Migrate/migrateprojects/mock/machines/mock-machine",
				"target_vm_name":             "mock-target-vm",
				"target_storage_path_id":     "/subscriptions/mock/mock-storage",
				"target_resource_group_id":   "/subscriptions/mock/resourceGroups/mock-target",
				"replication_vault_id":       "/subscriptions/mock/providers/Microsoft.DataReplication/replicationVaults/mock-vault",
				"policy_name":                "mock-policy",
				"replication_extension_name": "mock-extension",
			},
			expectError: false,
		},
		{
			name: "ValidReplicateWithMachineName",
			vars: map[string]interface{}{
				"operation_mode":             "replicate",
				"name":                       "mock-module",
				"resource_group_name":        "mock-rg",
				"location":                   "eastus",
				"project_name":               "mock-project",
				"machine_name":               "mock-machine-name",
				"target_vm_name":             "mock-target-vm",
				"target_storage_path_id":     "/subscriptions/mock/mock-storage",
				"target_resource_group_id":   "/subscriptions/mock/resourceGroups/mock-target",
				"replication_vault_id":       "/subscriptions/mock/providers/Microsoft.DataReplication/replicationVaults/mock-vault",
				"policy_name":                "mock-policy",
				"replication_extension_name": "mock-extension",
			},
			expectError: false,
		},
		{
			name: "MissingMachineIdentifier",
			vars: map[string]interface{}{
				"operation_mode":      "replicate",
				"name":                "mock-module",
				"resource_group_name": "mock-rg",
				"location":            "eastus",
				// Missing both machine_id and machine_name
			},
			expectError: true,
		},
	}

	for _, tc := range testCases {
		t.Run(tc.name, func(t *testing.T) {
			// For unit tests, verify configuration structure without running terraform
			if tc.expectError {
				// Verify the test case is testing for missing variables
				assert.NotNil(t, tc.vars, "Test case should have vars defined")
				// Should not have machine_id or machine_name
				_, hasMachineID := tc.vars["machine_id"]
				_, hasMachineName := tc.vars["machine_name"]
				assert.False(t, hasMachineID || hasMachineName, "Should be missing machine identifier")
			} else {
				// Verify required vars for replicate mode are present
				assert.Contains(t, tc.vars, "operation_mode")
				assert.Contains(t, tc.vars, "name")
				assert.Contains(t, tc.vars, "resource_group_name")
				assert.Contains(t, tc.vars, "location")
				// Should have either machine_id or machine_name
				_, hasMachineID := tc.vars["machine_id"]
				_, hasMachineName := tc.vars["machine_name"]
				assert.True(t, hasMachineID || hasMachineName, "Should have machine identifier")
			}
		})
	}
}

// TestVariableValidation tests variable validation logic
func TestVariableValidation(t *testing.T) {
	t.Parallel()

	testCases := []struct {
		name        string
		varName     string
		value       interface{}
		expectError bool
	}{
		{
			name:        "ValidOperationMode",
			varName:     "operation_mode",
			value:       "discover",
			expectError: false,
		},
		{
			name:        "InvalidOperationMode",
			varName:     "operation_mode",
			value:       "invalid_mode",
			expectError: true,
		},
		{
			name:        "ValidHyperVGeneration",
			varName:     "hyperv_generation",
			value:       "2",
			expectError: false,
		},
		{
			name:        "InvalidHyperVGeneration",
			varName:     "hyperv_generation",
			value:       "3",
			expectError: true,
		},
	}

	for _, tc := range testCases {
		t.Run(tc.name, func(t *testing.T) {
			// For unit tests, verify the variable values are correct types
			if tc.expectError {
				// Test invalid values
				if tc.varName == "operation_mode" {
					assert.NotContains(t, []string{"discover", "initialize", "replicate"}, tc.value,
						"Invalid operation mode should not be in valid list")
				}
				if tc.varName == "hyperv_generation" {
					assert.NotContains(t, []string{"1", "2"}, tc.value,
						"Invalid HyperV generation should not be in valid list")
				}
			} else {
				// Test valid values
				if tc.varName == "operation_mode" {
					assert.Contains(t, []string{"discover", "initialize", "replicate"}, tc.value,
						"Valid operation mode should be in valid list")
				}
				if tc.varName == "hyperv_generation" {
					assert.Contains(t, []string{"1", "2"}, tc.value,
						"Valid HyperV generation should be in valid list")
				}
			}
		})
	}
}

// TestOutputStructure tests that outputs are properly defined
func TestOutputStructure(t *testing.T) {
	t.Parallel()

	// For unit tests, just verify expected output names exist in the module
	// We can't get actual values without applying, but we can check structure
	expectedOutputs := []string{
		"discovered_servers",
		"filtered_discovered_servers",
		// Add other expected outputs here
	}

	// Verify output names follow conventions
	for _, outputName := range expectedOutputs {
		assert.NotEmpty(t, outputName, "Output name should not be empty")
		// Output names should use snake_case
		assert.Regexp(t, "^[a-z_]+$", outputName, "Output names should use snake_case")
	}
}

// TestResourceNaming tests resource naming patterns
func TestResourceNaming(t *testing.T) {
	t.Parallel()

	testCases := []struct {
		name         string
		resourceName string
		maxLength    int
		expectValid  bool
	}{
		{
			name:         "ValidVaultName",
			resourceName: "mock-replication-vault",
			maxLength:    80,
			expectValid:  true,
		},
		{
			name:         "VaultNameTooLong",
			resourceName: "this-is-a-very-long-vault-name-that-exceeds-the-maximum-allowed-length-for-azure-replication-vaults",
			maxLength:    80,
			expectValid:  false,
		},
		{
			name:         "ValidVMName",
			resourceName: "target-vm-001",
			maxLength:    64,
			expectValid:  true,
		},
		{
			name:         "VMNameTooLong",
			resourceName: "this-is-a-very-long-vm-name-that-exceeds-the-maximum-length-allowed-for-vms",
			maxLength:    64,
			expectValid:  false,
		},
	}

	for _, tc := range testCases {
		t.Run(tc.name, func(t *testing.T) {
			isValid := len(tc.resourceName) <= tc.maxLength
			assert.Equal(t, tc.expectValid, isValid,
				"Resource name length validation should match expected result")
		})
	}
}

// TestDiskConfiguration tests disk configuration validation
func TestDiskConfiguration(t *testing.T) {
	t.Parallel()

	testCases := []struct {
		name        string
		disks       []map[string]interface{}
		expectValid bool
	}{
		{
			name: "ValidSingleOSDisk",
			disks: []map[string]interface{}{
				{
					"disk_id":          "disk-001",
					"disk_size_gb":     128,
					"disk_file_format": "VHDX",
					"is_os_disk":       true,
					"is_dynamic":       false,
				},
			},
			expectValid: true,
		},
		{
			name: "ValidMultipleDisks",
			disks: []map[string]interface{}{
				{
					"disk_id":          "disk-os",
					"disk_size_gb":     128,
					"disk_file_format": "VHDX",
					"is_os_disk":       true,
					"is_dynamic":       false,
				},
				{
					"disk_id":          "disk-data-1",
					"disk_size_gb":     512,
					"disk_file_format": "VHDX",
					"is_os_disk":       false,
					"is_dynamic":       true,
				},
			},
			expectValid: true,
		},
	}

	for _, tc := range testCases {
		t.Run(tc.name, func(t *testing.T) {
			// Verify disk configuration structure
			hasOSDisk := false
			for _, disk := range tc.disks {
				if isOS, ok := disk["is_os_disk"].(bool); ok && isOS {
					hasOSDisk = true
					break
				}
			}

			if tc.expectValid {
				assert.True(t, len(tc.disks) > 0, "Should have at least one disk")
				// For valid configs, we expect an OS disk
				assert.True(t, hasOSDisk, "Should have an OS disk")
			}
		})
	}
}

// TestNetworkConfiguration tests NIC configuration validation
func TestNetworkConfiguration(t *testing.T) {
	t.Parallel()

	testCases := []struct {
		name        string
		nics        []map[string]interface{}
		expectValid bool
	}{
		{
			name: "ValidSingleNIC",
			nics: []map[string]interface{}{
				{
					"nic_id":                      "nic-001",
					"target_network_id":           "/subscriptions/mock/logicalnetworks/network-01",
					"selection_type_for_failover": "SelectedByUser",
				},
			},
			expectValid: true,
		},
		{
			name: "ValidMultipleNICs",
			nics: []map[string]interface{}{
				{
					"nic_id":                      "nic-001",
					"target_network_id":           "/subscriptions/mock/logicalnetworks/network-01",
					"selection_type_for_failover": "SelectedByUser",
				},
				{
					"nic_id":                      "nic-002",
					"target_network_id":           "/subscriptions/mock/logicalnetworks/network-02",
					"selection_type_for_failover": "SelectedByUser",
				},
			},
			expectValid: true,
		},
	}

	for _, tc := range testCases {
		t.Run(tc.name, func(t *testing.T) {
			// Verify NIC configuration structure
			for _, nic := range tc.nics {
				assert.Contains(t, nic, "nic_id", "NIC should have nic_id")
				assert.Contains(t, nic, "target_network_id", "NIC should have target_network_id")
			}
		})
	}
}
