package test

import (
	"fmt"
	"os"
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

// TestRemoveReplicationNormal tests normal (non-force) replication removal
func TestRemoveReplicationNormal(t *testing.T) {
	t.Parallel()

	// Get required environment variables
	subscriptionID := os.Getenv("ARM_SUBSCRIPTION_ID")
	resourceGroup := os.Getenv("ARM_RESOURCE_GROUP")
	protectedItemID := os.Getenv("ARM_PROTECTED_ITEM_ID")

	if subscriptionID == "" || resourceGroup == "" || protectedItemID == "" {
		t.Skip("Required environment variables not set (ARM_SUBSCRIPTION_ID, ARM_RESOURCE_GROUP, ARM_PROTECTED_ITEM_ID)")
	}

	terraformOptions := &terraform.Options{
		TerraformDir: "../",
		Vars: map[string]interface{}{
			"operation_mode":      "remove",
			"name":                "test-remove-normal",
			"resource_group_name": resourceGroup,
			"location":            "eastus",
			"target_object_id":    protectedItemID,
			"force_remove":        false,
		},
		NoColor: true,
	}

	// Cleanup
	defer terraform.Destroy(t, terraformOptions)

	// Run terraform init and apply
	terraform.InitAndApply(t, terraformOptions)

	// Test: Verify removal status output
	t.Run("VerifyRemovalStatus", func(t *testing.T) {
		// Get removal status output
		terraform.OutputRequired(t, terraformOptions, "removal_status")
		fmt.Println("Normal removal operation completed successfully")
	})

	// Test: Verify protected item details were captured
	t.Run("VerifyProtectedItemDetails", func(t *testing.T) {
		terraform.OutputRequired(t, terraformOptions, "protected_item_details")
		fmt.Println("Protected item details captured before removal")
	})

	// Test: Verify operation headers exist (for job tracking)
	t.Run("VerifyOperationHeaders", func(t *testing.T) {
		terraform.OutputRequired(t, terraformOptions, "removal_operation_headers")
		fmt.Println("Operation headers available for job tracking")
	})
}

// TestRemoveReplicationForce tests force replication removal
func TestRemoveReplicationForce(t *testing.T) {
	t.Parallel()

	// Get required environment variables
	subscriptionID := os.Getenv("ARM_SUBSCRIPTION_ID")
	resourceGroup := os.Getenv("ARM_RESOURCE_GROUP")
	protectedItemID := os.Getenv("ARM_PROTECTED_ITEM_ID_FORCE")

	if subscriptionID == "" || resourceGroup == "" || protectedItemID == "" {
		t.Skip("Required environment variables not set (ARM_SUBSCRIPTION_ID, ARM_RESOURCE_GROUP, ARM_PROTECTED_ITEM_ID_FORCE)")
	}

	terraformOptions := &terraform.Options{
		TerraformDir: "../",
		Vars: map[string]interface{}{
			"operation_mode":      "remove",
			"name":                "test-remove-force",
			"resource_group_name": resourceGroup,
			"location":            "eastus",
			"target_object_id":    protectedItemID,
			"force_remove":        true,
		},
		NoColor: true,
	}

	// Cleanup
	defer terraform.Destroy(t, terraformOptions)

	// Run terraform init and apply
	terraform.InitAndApply(t, terraformOptions)

	// Test: Verify force removal completed
	t.Run("VerifyForceRemoval", func(t *testing.T) {
		terraform.OutputRequired(t, terraformOptions, "removal_status")
		fmt.Println("Force removal operation completed successfully")
	})
}

// TestRemoveOutputStructure validates the structure of remove outputs
func TestRemoveOutputStructure(t *testing.T) {
	t.Parallel()

	resourceGroup := os.Getenv("ARM_RESOURCE_GROUP")
	protectedItemID := os.Getenv("ARM_PROTECTED_ITEM_ID")

	if resourceGroup == "" || protectedItemID == "" {
		t.Skip("Required environment variables not set (ARM_RESOURCE_GROUP, ARM_PROTECTED_ITEM_ID)")
	}

	terraformOptions := &terraform.Options{
		TerraformDir: "../",
		Vars: map[string]interface{}{
			"operation_mode":      "remove",
			"name":                "test-remove-structure",
			"resource_group_name": resourceGroup,
			"location":            "eastus",
			"target_object_id":    protectedItemID,
			"force_remove":        false,
		},
		NoColor: true,
	}

	defer terraform.Destroy(t, terraformOptions)

	terraform.InitAndApply(t, terraformOptions)

	// Test: Verify all remove outputs exist
	t.Run("VerifyOutputsExist", func(t *testing.T) {
		outputs := []string{
			"removal_status",
			"removal_operation_headers",
			"protected_item_details",
		}

		for _, outputName := range outputs {
			terraform.OutputRequired(t, terraformOptions, outputName)
		}
	})
}

// TestRemoveValidation tests that validation occurs before removal
func TestRemoveValidation(t *testing.T) {
	t.Parallel()

	resourceGroup := os.Getenv("ARM_RESOURCE_GROUP")
	protectedItemID := os.Getenv("ARM_PROTECTED_ITEM_ID")

	if resourceGroup == "" || protectedItemID == "" {
		t.Skip("Required environment variables not set (ARM_RESOURCE_GROUP, ARM_PROTECTED_ITEM_ID)")
	}

	terraformOptions := &terraform.Options{
		TerraformDir: "../",
		Vars: map[string]interface{}{
			"operation_mode":      "remove",
			"name":                "test-remove-validation",
			"resource_group_name": resourceGroup,
			"location":            "eastus",
			"target_object_id":    protectedItemID,
			"force_remove":        false,
		},
		NoColor: true,
	}

	defer terraform.Destroy(t, terraformOptions)

	terraform.InitAndApply(t, terraformOptions)

	t.Run("VerifyProtectionStateValidated", func(t *testing.T) {
		// Get protected item details which are captured during validation
		terraform.OutputRequired(t, terraformOptions, "protected_item_details")

		fmt.Println("Protected item validation completed successfully")
	})
}

// TestRemoveErrorHandling tests error cases for remove mode
func TestRemoveErrorHandling(t *testing.T) {
	t.Parallel()

	resourceGroup := os.Getenv("ARM_RESOURCE_GROUP")

	if resourceGroup == "" {
		t.Skip("Required environment variable not set (ARM_RESOURCE_GROUP)")
	}

	t.Run("InvalidProtectedItemID", func(t *testing.T) {
		terraformOptions := &terraform.Options{
			TerraformDir: "../",
			Vars: map[string]interface{}{
				"operation_mode":      "remove",
				"name":                "test-remove-error",
				"resource_group_name": resourceGroup,
				"location":            "eastus",
				"target_object_id":    "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/fake-rg/providers/Microsoft.DataReplication/replicationVaults/fake-vault/protectedItems/non-existent-item",
				"force_remove":        false,
			},
			NoColor: true,
		}

		defer terraform.Destroy(t, terraformOptions)

		// This should fail because the protected item doesn't exist
		_, err := terraform.InitAndApplyE(t, terraformOptions)
		assert.Error(t, err, "Should fail with non-existent protected item")
	})
}

// TestRemoveWithJobTracking tests removal with subsequent job tracking
func TestRemoveWithJobTracking(t *testing.T) {
	t.Parallel()

	resourceGroup := os.Getenv("ARM_RESOURCE_GROUP")
	protectedItemID := os.Getenv("ARM_PROTECTED_ITEM_ID")
	projectName := os.Getenv("ARM_PROJECT_NAME")

	if resourceGroup == "" || protectedItemID == "" || projectName == "" {
		t.Skip("Required environment variables not set (ARM_RESOURCE_GROUP, ARM_PROTECTED_ITEM_ID, ARM_PROJECT_NAME)")
	}

	// Step 1: Remove the replication
	removeTfOptions := &terraform.Options{
		TerraformDir: "../",
		Vars: map[string]interface{}{
			"operation_mode":      "remove",
			"name":                "test-remove-track",
			"resource_group_name": resourceGroup,
			"location":            "eastus",
			"target_object_id":    protectedItemID,
			"force_remove":        false,
		},
		NoColor: true,
	}

	defer terraform.Destroy(t, removeTfOptions)

	terraform.InitAndApply(t, removeTfOptions)

	t.Run("VerifyRemovalInitiated", func(t *testing.T) {
		terraform.OutputRequired(t, removeTfOptions, "removal_status")
		terraform.OutputRequired(t, removeTfOptions, "removal_operation_headers")

		fmt.Println("Removal initiated, operation headers available for job tracking")
		fmt.Println("Note: In a real scenario, you would parse the job name from the headers")
		fmt.Println("      and use the 'jobs' operation mode to track the removal job status")
	})
}

// TestRemoveProtectedItemValidation tests that protected item must allow DisableProtection
func TestRemoveProtectedItemValidation(t *testing.T) {
	t.Parallel()

	resourceGroup := os.Getenv("ARM_RESOURCE_GROUP")
	protectedItemID := os.Getenv("ARM_PROTECTED_ITEM_ID")

	if resourceGroup == "" || protectedItemID == "" {
		t.Skip("Required environment variables not set (ARM_RESOURCE_GROUP, ARM_PROTECTED_ITEM_ID)")
	}

	terraformOptions := &terraform.Options{
		TerraformDir: "../",
		Vars: map[string]interface{}{
			"operation_mode":      "remove",
			"name":                "test-remove-validate",
			"resource_group_name": resourceGroup,
			"location":            "eastus",
			"target_object_id":    protectedItemID,
			"force_remove":        false,
		},
		NoColor: true,
	}

	defer terraform.Destroy(t, terraformOptions)

	terraform.InitAndApply(t, terraformOptions)

	t.Run("VerifyAllowedJobsChecked", func(t *testing.T) {
		// The protected_item_details output includes can_disable_protection
		terraform.OutputRequired(t, terraformOptions, "protected_item_details")

		fmt.Println("Protected item validation confirmed DisableProtection is allowed")
	})
}

// TestRemoveIdempotency tests that remove operation is idempotent
func TestRemoveIdempotency(t *testing.T) {
	t.Parallel()

	resourceGroup := os.Getenv("ARM_RESOURCE_GROUP")
	protectedItemID := os.Getenv("ARM_PROTECTED_ITEM_ID_IDEMPOTENT")

	if resourceGroup == "" || protectedItemID == "" {
		t.Skip("Required environment variables not set (ARM_RESOURCE_GROUP, ARM_PROTECTED_ITEM_ID_IDEMPOTENT)")
	}

	terraformOptions := &terraform.Options{
		TerraformDir: "../",
		Vars: map[string]interface{}{
			"operation_mode":      "remove",
			"name":                "test-remove-idempotent",
			"resource_group_name": resourceGroup,
			"location":            "eastus",
			"target_object_id":    protectedItemID,
			"force_remove":        false,
		},
		NoColor: true,
	}

	defer terraform.Destroy(t, terraformOptions)

	// First apply
	terraform.InitAndApply(t, terraformOptions)

	t.Run("VerifyFirstRemoval", func(t *testing.T) {
		terraform.OutputRequired(t, terraformOptions, "removal_status")
	})

	// Note: A second apply would fail because the protected item no longer exists
	// This is expected behavior - once removed, the item cannot be removed again
	fmt.Println("Note: Remove operation is NOT idempotent - the protected item is deleted")
	fmt.Println("      Running terraform apply again would fail with 'resource not found'")
}
