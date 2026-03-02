# Example: End-to-End VM Replication and Migration
#
# This example demonstrates a complete migration workflow in a single configuration:
#   Step 1: Replicate - Start VM replication to Azure Stack HCI
#   Step 2: Get Status - Check if initial replication has completed (state = "Protected")
#   Step 3: Migrate - If replication is complete, perform planned failover (migration)
#
# Usage:
#   1. First run: terraform apply
#      - Creates the replication and checks status
#      - If replication is still in progress, outputs will show the current state
#
#   2. Poll status: terraform apply (re-run periodically)
#      - Each apply refreshes the replication state
#      - Once state = "Protected", set perform_migration = true
#
#   3. Migrate: terraform apply -var="perform_migration=true"
#      - Triggers planned failover once replication is complete
#

terraform {
  required_version = ">= 1.9"

  required_providers {
    azapi = {
      source  = "azure/azapi"
      version = "~> 2.4"
    }
  }
}

provider "azapi" {}

# The protected item ID follows a predictable pattern based on the machine_id
# and replication vault. We construct it from known inputs so it's available at
# plan time (avoiding "count depends on unknown value" errors).
locals {
  protected_item_id = "${var.replication_vault_id}/protectedItems/${basename(var.machine_id)}"
}

# ========================================
# STEP 1: REPLICATE VM
# ========================================
# Start replication of the source VM to Azure Stack HCI.
# This creates a protected item in the replication vault.
module "replicate_vm" {
  source = "../../"

  location                   = var.location
  name                       = "e2e-replicate"
  parent_id                  = var.parent_id
  custom_location_id         = var.custom_location_id
  disks_to_include           = var.disks_to_include
  hyperv_generation          = var.hyperv_generation
  instance_type              = var.instance_type
  is_dynamic_memory_enabled  = var.is_dynamic_memory_enabled
  machine_id                 = var.machine_id
  nic_id                     = var.nic_id
  nics_to_include            = var.nics_to_include
  operation_mode             = "replicate"
  os_disk_id                 = var.os_disk_id
  os_disk_size_gb            = var.os_disk_size_gb
  policy_name                = var.policy_name
  project_name               = var.project_name
  replication_extension_name = var.replication_extension_name
  replication_vault_id       = var.replication_vault_id
  run_as_account_id          = var.run_as_account_id
  source_appliance_name      = var.source_appliance_name
  source_fabric_agent_name   = var.source_fabric_agent_name
  source_vm_cpu_cores        = var.source_vm_cpu_cores
  source_vm_ram_mb           = var.source_vm_ram_mb
  tags                       = var.tags
  target_appliance_name      = var.target_appliance_name
  target_fabric_agent_name   = var.target_fabric_agent_name
  target_hci_cluster_id      = var.target_hci_cluster_id
  target_resource_group_id   = var.target_resource_group_id
  target_storage_path_id     = var.target_storage_path_id
  target_virtual_switch_id   = var.target_virtual_switch_id
  target_vm_cpu_cores        = var.target_vm_cpu_cores
  target_vm_name             = var.target_vm_name
  target_vm_ram_mb           = var.target_vm_ram_mb
}

# ========================================
# STEP 1.5: WAIT FOR REPLICATION TO COMPLETE
# ========================================
# Polls the protected item status via Azure CLI until initial replication
# finishes. This can take anywhere from minutes to hours depending on VM
# disk size and network bandwidth.
resource "terraform_data" "wait_for_replication" {
  depends_on = [module.replicate_vm]

  # Re-run the wait whenever the protected item is (re)created
  triggers_replace = module.replicate_vm.protected_item_id

  provisioner "local-exec" {
    interpreter = ["pwsh", "-Command"]
    command     = <<-EOT
      $ErrorActionPreference = 'Stop'
      $resourceId   = "${local.protected_item_id}"
      $apiVersion   = "2024-09-01"
      $maxAttempts  = 360   # up to 6 hours with 60s intervals
      $sleepSeconds = 60

      Write-Host "Waiting for initial replication to complete..."
      Write-Host "Protected item: $resourceId"

      for ($i = 1; $i -le $maxAttempts; $i++) {
        try {
          $json = az rest --method GET `
            --url "https://management.azure.com$${resourceId}?api-version=$${apiVersion}" `
            --output json 2>&1
          $response = $json | ConvertFrom-Json
        } catch {
          Write-Host "[$i/$maxAttempts] Failed to query status: $_  — retrying in $${sleepSeconds}s"
          Start-Sleep -Seconds $sleepSeconds
          continue
        }

        $state       = $response.properties.protectionState
        $health      = $response.properties.replicationHealth
        $allowedJobs = $response.properties.allowedJobs

        Write-Host "[$i/$maxAttempts] State: $state | Health: $health | AllowedJobs: $($allowedJobs -join ', ')"

        # Success: replication is complete and VM is protected
        if ($allowedJobs -contains 'PlannedFailover') {
          Write-Host "`nReplication complete — VM is ready for migration."
          exit 0
        }

        # Also accept ProtectedItemCreated as a completed state
        if ($state -eq 'ProtectedItemCreated') {
          Write-Host "`nReplication complete — protected item created."
          exit 0
        }

        # Fail fast on error states
        if ($state -match 'Failed|Error') {
          Write-Host "`nReplication FAILED with state: $state"
          exit 1
        }

        Write-Host "  Waiting $${sleepSeconds}s before next check..."
        Start-Sleep -Seconds $sleepSeconds
      }

      Write-Host "`nTimeout: replication did not complete within $($maxAttempts * $sleepSeconds / 3600) hours."
      exit 1
    EOT
  }
}

# ========================================
# STEP 2: GET REPLICATION STATUS
# ========================================
# After replication is created, check the current status.
# The protected item ID comes from the replicate step output.
module "check_status" {
  source = "../../"

  depends_on = [terraform_data.wait_for_replication]

  location          = var.location
  name              = "e2e-check-status"
  parent_id         = var.parent_id
  instance_type     = var.instance_type
  operation_mode    = "get"
  project_name      = var.project_name
  protected_item_id = local.protected_item_id
  tags              = var.tags
}

# ========================================
# STEP 3: MIGRATE (Planned Failover)
# ========================================
# Only runs when perform_migration = true.
# The user should set this after confirming replication state = "Protected".
module "migrate_vm" {
  source = "../../"
  count  = var.perform_migration ? 1 : 0

  depends_on = [module.check_status]

  location           = var.location
  name               = "e2e-migrate"
  parent_id          = var.parent_id
  instance_type      = var.instance_type
  operation_mode     = "migrate"
  protected_item_id  = local.protected_item_id
  shutdown_source_vm = var.shutdown_source_vm
  tags               = var.tags
}
