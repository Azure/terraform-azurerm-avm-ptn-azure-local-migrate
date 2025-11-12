# Makefile for running Terraform tests

.PHONY: help test test-unit test-integration test-discover test-initialize test-replicate test-workflow test-short test-clean deps fmt vet

# Default target
help:
	@echo "Available targets:"
	@echo ""
	@echo "Dependencies:"
	@echo "  make deps              - Download Go dependencies"
	@echo ""
	@echo "Unit Tests (Fast, No Azure):"
	@echo "  make test-unit         - Run unit tests (mock values, no resources)"
	@echo ""
	@echo "Integration Tests (Slow, Creates Azure Resources):"
	@echo "  make test-integration  - Run ALL integration tests (30-60min, costs money!)"
	@echo "  make test-discover     - Run discover integration tests"
	@echo "  make test-initialize   - Run initialize integration tests"
	@echo "  make test-replicate    - Run replicate integration tests"
	@echo "  make test-workflow     - Run end-to-end workflow tests"
	@echo ""
	@echo "All Tests:"
	@echo "  make test              - Run unit + integration tests (60min+)"
	@echo ""
	@echo "Utilities:"
	@echo "  make test-clean        - Clean test cache"
	@echo "  make fmt               - Format Go code"
	@echo "  make vet               - Run go vet"

# Download dependencies
deps:
	@echo "Downloading dependencies..."
	go mod download

# Run UNIT tests only (fast, no Azure resources)
test-unit: deps
	@echo "=========================================="
	@echo "Running UNIT tests (mock values, no Azure resources)"
	@echo "Duration: 1-5 minutes | Cost: FREE"
	@echo "=========================================="
	go test -v -timeout 5m -run "^TestModule|^TestDiscover.*Configuration|^TestInitialize.*Configuration|^TestReplicate.*Configuration|^TestVariable|^TestResource|^TestDisk|^TestNetwork"

# Run ALL INTEGRATION tests (slow, creates real Azure resources)
test-integration: deps
	@echo "=========================================="
	@echo "WARNING: Running INTEGRATION tests"
	@echo "This will CREATE REAL Azure resources and COST MONEY!"
	@echo "Duration: 30-60 minutes | Cost: $$$"
	@echo "=========================================="
	@sleep 3
	go test -v -timeout 60m -run "^TestDiscover|^TestInitialize|^TestReplicate|^TestIntegration"

# Run all tests (unit + integration)
test: test-unit test-integration

# Run discover integration tests
test-discover: deps
	@echo "Running discover integration tests (creates Azure resources)..."
	go test -v -timeout 20m -run "^TestDiscoverCommand"

# Run initialize integration tests
test-initialize: deps
	@echo "Running initialize integration tests (creates Azure resources)..."
	go test -v -timeout 30m -run "^TestInitializeCommand"

# Run replicate integration tests
test-replicate: deps
	@echo "Running replicate integration tests (creates Azure resources)..."
	go test -v -timeout 30m -run "^TestReplicateCommand"

# Run end-to-end workflow integration tests
test-workflow: deps
	@echo "Running workflow integration tests (creates Azure resources)..."
	go test -v -timeout 60m -run "^TestIntegrationWorkflow|^TestFullMigrationWorkflow"
	@echo "Running integration tests..."
	cd tests && go test -v -timeout 60m -run TestIntegration

# Clean test cache
test-clean:
	@echo "Cleaning test cache..."
	cd tests && go clean -testcache

# Format Go code
fmt:
	@echo "Formatting Go code..."
	cd tests && go fmt ./...

# Run go vet
vet:
	@echo "Running go vet..."
	cd tests && go vet ./...

# Validate environment variables
check-env:
	@echo "Checking required environment variables..."
	@test -n "$(ARM_SUBSCRIPTION_ID)" || (echo "ERROR: ARM_SUBSCRIPTION_ID is not set" && exit 1)
	@test -n "$(ARM_TENANT_ID)" || (echo "ERROR: ARM_TENANT_ID is not set" && exit 1)
	@test -n "$(ARM_CLIENT_ID)" || (echo "ERROR: ARM_CLIENT_ID is not set" && exit 1)
	@test -n "$(ARM_CLIENT_SECRET)" || (echo "ERROR: ARM_CLIENT_SECRET is not set" && exit 1)
	@echo "All required environment variables are set"
