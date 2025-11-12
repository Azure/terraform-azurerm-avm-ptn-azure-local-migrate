package test

import (
	"fmt"
	"os"
	"testing"
)

// TestHelper contains common test utilities
type TestHelper struct {
	t *testing.T
}

// NewTestHelper creates a new test helper instance
func NewTestHelper(t *testing.T) *TestHelper {
	return &TestHelper{t: t}
}

// GetRequiredEnvVar retrieves an environment variable or skips the test if not set
func (h *TestHelper) GetRequiredEnvVar(key string) string {
	value := os.Getenv(key)
	if value == "" {
		h.t.Skipf("Environment variable %s is required but not set", key)
	}
	return value
}

// GetOptionalEnvVar retrieves an environment variable with a default value
func (h *TestHelper) GetOptionalEnvVar(key, defaultValue string) string {
	value := os.Getenv(key)
	if value == "" {
		return defaultValue
	}
	return value
}

// ValidateAzureResourceID validates that a string is a valid Azure resource ID
func ValidateAzureResourceID(resourceID string) error {
	if resourceID == "" {
		return fmt.Errorf("resource ID cannot be empty")
	}

	// Basic validation: should start with /subscriptions/
	if len(resourceID) < 15 || resourceID[:15] != "/subscriptions/" {
		return fmt.Errorf("invalid Azure resource ID format: %s", resourceID)
	}

	return nil
}

// ValidateResourceName validates Azure resource naming conventions
func ValidateResourceName(name string, maxLength int) error {
	if name == "" {
		return fmt.Errorf("resource name cannot be empty")
	}

	if len(name) > maxLength {
		return fmt.Errorf("resource name exceeds maximum length of %d: %s", maxLength, name)
	}

	// Additional validation rules can be added here

	return nil
}

// Common test constants
const (
	// Default timeout values
	DefaultApplyTimeout   = 30 // minutes
	DefaultDestroyTimeout = 20 // minutes

	// Azure resource naming limits
	MaxVaultNameLength         = 80
	MaxStorageAccountNameLength = 24
	MaxVMNameLength            = 64
	MaxResourceGroupNameLength = 90

	// Environment variable keys
	EnvSubscriptionID    = "ARM_SUBSCRIPTION_ID"
	EnvHCISubscriptionID = "ARM_HCI_SUBSCRIPTION_ID"
	EnvTenantID          = "ARM_TENANT_ID"
	EnvClientID          = "ARM_CLIENT_ID"
	EnvClientSecret      = "ARM_CLIENT_SECRET"
)

// GetTestTags returns common tags for test resources
func GetTestTags() map[string]string {
	return map[string]string{
		"Environment": "Test",
		"ManagedBy":   "Terratest",
		"Purpose":     "AutomatedTesting",
	}
}

// IsRunningInCI checks if tests are running in a CI environment
func IsRunningInCI() bool {
	// Check common CI environment variables
	ciEnvVars := []string{
		"CI",
		"CONTINUOUS_INTEGRATION",
		"GITHUB_ACTIONS",
		"AZURE_PIPELINES",
	}

	for _, envVar := range ciEnvVars {
		if os.Getenv(envVar) != "" {
			return true
		}
	}

	return false
}
