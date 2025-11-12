package test

import (
	"fmt"
	"os"
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

// TestJobsListAll tests listing all replication jobs
func TestJobsListAll(t *testing.T) {
	t.Parallel()

	// Get required environment variables
	subscriptionID := os.Getenv("ARM_SUBSCRIPTION_ID")
	resourceGroup := os.Getenv("ARM_RESOURCE_GROUP")
	projectName := os.Getenv("ARM_PROJECT_NAME")

	if subscriptionID == "" || resourceGroup == "" || projectName == "" {
		t.Skip("Required environment variables not set (ARM_SUBSCRIPTION_ID, ARM_RESOURCE_GROUP, ARM_PROJECT_NAME)")
	}

	terraformOptions := &terraform.Options{
		TerraformDir: "../",
		Vars: map[string]interface{}{
			"operation_mode":      "jobs",
			"name":                "test-jobs-list",
			"resource_group_name": resourceGroup,
			"location":            "eastus",
			"project_name":        projectName,
		},
		NoColor: true,
	}

	// Cleanup
	defer terraform.Destroy(t, terraformOptions)

	// Run terraform init and apply
	terraform.InitAndApply(t, terraformOptions)

	// Test: Verify jobs output structure
	t.Run("VerifyJobsListOutput", func(t *testing.T) {
		// Get the jobs count output
		jobsCountStr := terraform.Output(t, terraformOptions, "replication_jobs_count")
		assert.NotEmpty(t, jobsCountStr, "Jobs count should not be empty")

		// Get the vault ID used for jobs
		vaultID := terraform.Output(t, terraformOptions, "vault_id_for_jobs")
		assert.NotEmpty(t, vaultID, "Vault ID should not be empty")
		assert.Contains(t, vaultID, "Microsoft.DataReplication/replicationVaults",
			"Vault ID should contain correct resource type")
	})
}

// TestJobsGetSpecific tests retrieving a specific replication job
func TestJobsGetSpecific(t *testing.T) {
	t.Parallel()

	// Get required environment variables
	subscriptionID := os.Getenv("ARM_SUBSCRIPTION_ID")
	resourceGroup := os.Getenv("ARM_RESOURCE_GROUP")
	vaultID := os.Getenv("ARM_VAULT_ID")
	jobName := os.Getenv("ARM_JOB_NAME")

	if subscriptionID == "" || resourceGroup == "" || vaultID == "" || jobName == "" {
		t.Skip("Required environment variables not set (ARM_SUBSCRIPTION_ID, ARM_RESOURCE_GROUP, ARM_VAULT_ID, ARM_JOB_NAME)")
	}

	terraformOptions := &terraform.Options{
		TerraformDir: "../",
		Vars: map[string]interface{}{
			"operation_mode":       "jobs",
			"name":                 "test-jobs-get",
			"resource_group_name":  resourceGroup,
			"location":             "eastus",
			"replication_vault_id": vaultID,
			"job_name":             jobName,
		},
		NoColor: true,
	}

	// Cleanup
	defer terraform.Destroy(t, terraformOptions)

	// Run terraform init and apply
	terraform.InitAndApply(t, terraformOptions)

	// Test: Verify job details output
	t.Run("VerifyJobDetails", func(t *testing.T) {
		// Get the job details - output is a complex object, so we use OutputRequired
		// which will fail if the output doesn't exist
		terraform.OutputRequired(t, terraformOptions, "replication_job")

		// The output exists, which means we successfully retrieved the job
		fmt.Printf("Successfully retrieved job details for job: %s\n", jobName)
	})
}

// TestJobsOutputStructure validates the structure of job outputs
func TestJobsOutputStructure(t *testing.T) {
	t.Parallel()

	// Get required environment variables
	resourceGroup := os.Getenv("ARM_RESOURCE_GROUP")
	projectName := os.Getenv("ARM_PROJECT_NAME")

	if resourceGroup == "" || projectName == "" {
		t.Skip("Required environment variables not set (ARM_RESOURCE_GROUP, ARM_PROJECT_NAME)")
	}

	terraformOptions := &terraform.Options{
		TerraformDir: "../",
		Vars: map[string]interface{}{
			"operation_mode":      "jobs",
			"name":                "test-jobs-structure",
			"resource_group_name": resourceGroup,
			"location":            "eastus",
			"project_name":        projectName,
		},
		NoColor: true,
	}

	// Cleanup
	defer terraform.Destroy(t, terraformOptions)

	// Run terraform init and apply
	terraform.InitAndApply(t, terraformOptions)

	// Test: Verify all job outputs exist
	t.Run("VerifyOutputsExist", func(t *testing.T) {
		outputs := []string{
			"replication_jobs",
			"replication_jobs_count",
			"vault_id_for_jobs",
		}

		for _, outputName := range outputs {
			terraform.OutputRequired(t, terraformOptions, outputName)
		}
	})
}

// TestJobsWithProjectName tests job retrieval using project name
func TestJobsWithProjectName(t *testing.T) {
	t.Parallel()

	resourceGroup := os.Getenv("ARM_RESOURCE_GROUP")
	projectName := os.Getenv("ARM_PROJECT_NAME")

	if resourceGroup == "" || projectName == "" {
		t.Skip("Required environment variables not set (ARM_RESOURCE_GROUP, ARM_PROJECT_NAME)")
	}

	terraformOptions := &terraform.Options{
		TerraformDir: "../",
		Vars: map[string]interface{}{
			"operation_mode":      "jobs",
			"name":                "test-jobs-project",
			"resource_group_name": resourceGroup,
			"location":            "eastus",
			"project_name":        projectName,
		},
		NoColor: true,
	}

	defer terraform.Destroy(t, terraformOptions)

	terraform.InitAndApply(t, terraformOptions)

	t.Run("VerifyVaultResolution", func(t *testing.T) {
		vaultID := terraform.Output(t, terraformOptions, "vault_id_for_jobs")
		assert.NotEmpty(t, vaultID, "Vault should be resolved from project name")
		assert.Contains(t, vaultID, "replicationVaults", "Should be a valid vault ID")
	})
}

// TestJobsWithVaultID tests job retrieval using explicit vault ID
func TestJobsWithVaultID(t *testing.T) {
	t.Parallel()

	resourceGroup := os.Getenv("ARM_RESOURCE_GROUP")
	vaultID := os.Getenv("ARM_VAULT_ID")

	if resourceGroup == "" || vaultID == "" {
		t.Skip("Required environment variables not set (ARM_RESOURCE_GROUP, ARM_VAULT_ID)")
	}

	terraformOptions := &terraform.Options{
		TerraformDir: "../",
		Vars: map[string]interface{}{
			"operation_mode":       "jobs",
			"name":                 "test-jobs-vault",
			"resource_group_name":  resourceGroup,
			"location":             "eastus",
			"replication_vault_id": vaultID,
		},
		NoColor: true,
	}

	defer terraform.Destroy(t, terraformOptions)

	terraform.InitAndApply(t, terraformOptions)

	t.Run("VerifyVaultUsed", func(t *testing.T) {
		outputVaultID := terraform.Output(t, terraformOptions, "vault_id_for_jobs")
		assert.Equal(t, vaultID, outputVaultID, "Output vault ID should match input")
	})
}

// TestJobsErrorHandling tests error cases for jobs mode
func TestJobsErrorHandling(t *testing.T) {
	t.Parallel()

	resourceGroup := os.Getenv("ARM_RESOURCE_GROUP")

	if resourceGroup == "" {
		t.Skip("Required environment variable not set (ARM_RESOURCE_GROUP)")
	}

	t.Run("InvalidJobName", func(t *testing.T) {
		terraformOptions := &terraform.Options{
			TerraformDir: "../",
			Vars: map[string]interface{}{
				"operation_mode":       "jobs",
				"name":                 "test-jobs-error",
				"resource_group_name":  resourceGroup,
				"location":             "eastus",
				"replication_vault_id": "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/fake-rg/providers/Microsoft.DataReplication/replicationVaults/fake-vault",
				"job_name":             "non-existent-job-12345",
			},
			NoColor: true,
		}

		defer terraform.Destroy(t, terraformOptions)

		// This should fail because the job doesn't exist
		_, err := terraform.InitAndApplyE(t, terraformOptions)
		assert.Error(t, err, "Should fail with non-existent job")
	})
}
