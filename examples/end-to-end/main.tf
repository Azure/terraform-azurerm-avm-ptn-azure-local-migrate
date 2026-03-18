# Example: End-to-End Multi-VM Replication and Migration
#
# This example demonstrates a complete migration workflow for multiple VMs:
#   Step 0: Initialize - Set up replication infrastructure (vault, policy, extension)
#   Step 1: Replicate - Start VM replication to Azure Stack HCI (for each VM)
#   Step 1.5: Wait - Poll until initial replication completes (for each VM)
#   Step 2: Get Status - Confirm replication state = "Protected" (for each VM)
#   Step 3: Migrate - Perform planned failover (for each VM)
#
# Usage:
#   terraform apply
#     - Initializes replication infrastructure if needed
#     - Replicates all VMs and waits for initial replication to complete
#     - Automatically migrates (planned failover) all VMs once ready
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

# ========================================
# STEP 0: INITIALIZE REPLICATION INFRASTRUCTURE
# ========================================
# Sets up the replication vault, policy, and extension.
# Skip this step if infrastructure already exists by setting skip_initialize = true.
module "initialize" {
  source = "../../"
  count  = var.skip_initialize ? 0 : 1

  location                           = var.location
  name                               = "e2e-initialize"
  parent_id                          = var.parent_id
  app_consistent_frequency_minutes   = var.app_consistent_frequency_minutes
  cache_storage_account_id           = var.cache_storage_account_id
  crash_consistent_frequency_minutes = var.crash_consistent_frequency_minutes
  instance_type                      = var.instance_type
  operation_mode                     = "initialize"
  project_name                       = var.project_name
  recovery_point_history_minutes     = var.recovery_point_history_minutes
  source_appliance_name              = var.source_appliance_name
  source_fabric_id                   = var.source_fabric_id
  tags                               = var.tags
  target_appliance_name              = var.target_appliance_name
  target_fabric_id                   = var.target_fabric_id
}

# The protected item ID follows a predictable pattern based on the machine_id
# and replication vault. We construct it from known inputs so it's available at
# plan time (avoiding "count depends on unknown value" errors).
#
# When initialize runs, we derive vault/policy/extension from its outputs.
# When skipped, we use the explicit variable values.
locals {
  policy_name = var.skip_initialize ? var.policy_name : basename(module.initialize[0].replication_policy_id)
  # Build a protected_item_id for each VM
  protected_item_ids = {
    for key, vm in var.vms : key => "${local.replication_vault_id}/protectedItems/${basename(vm.machine_id)}"
  }
  replication_extension_name = var.skip_initialize ? var.replication_extension_name : module.initialize[0].replication_extension_name
  replication_vault_id       = var.skip_initialize ? var.replication_vault_id : module.initialize[0].replication_vault_id
}

# ========================================
# STEP 1: REPLICATE VMs
# ========================================
# Start replication of each source VM to Azure Stack HCI.
# This creates a protected item in the replication vault per VM.
module "replicate_vm" {
  source   = "../../"
  for_each = var.vms

  location                   = var.location
  name                       = "e2e-replicate-${each.key}"
  parent_id                  = var.parent_id
  custom_location_id         = var.custom_location_id
  disks_to_include           = each.value.disks_to_include
  hyperv_generation          = each.value.hyperv_generation
  instance_type              = var.instance_type
  is_dynamic_memory_enabled  = each.value.is_dynamic_memory_enabled
  machine_id                 = each.value.machine_id
  nic_id                     = each.value.nic_id
  nics_to_include            = each.value.nics_to_include
  operation_mode             = "replicate"
  os_disk_id                 = each.value.os_disk_id
  os_disk_size_gb            = each.value.os_disk_size_gb
  policy_name                = local.policy_name
  project_name               = var.project_name
  replication_extension_name = local.replication_extension_name
  replication_vault_id       = local.replication_vault_id
  run_as_account_id          = var.run_as_account_id
  source_appliance_name      = var.source_appliance_name
  source_fabric_agent_name   = var.source_fabric_agent_name
  source_vm_cpu_cores        = each.value.source_vm_cpu_cores
  source_vm_ram_mb           = each.value.source_vm_ram_mb
  tags                       = var.tags
  target_appliance_name      = var.target_appliance_name
  target_fabric_agent_name   = var.target_fabric_agent_name
  target_hci_cluster_id      = var.target_hci_cluster_id
  target_resource_group_id   = var.target_resource_group_id
  target_storage_path_id     = var.target_storage_path_id
  target_virtual_switch_id   = var.target_virtual_switch_id
  target_vm_cpu_cores        = each.value.target_vm_cpu_cores
  target_vm_name             = each.value.target_vm_name
  target_vm_ram_mb           = each.value.target_vm_ram_mb

  depends_on = [module.initialize]
}

# ========================================
# STEP 1.5: WAIT FOR REPLICATION TO COMPLETE
# ========================================
# Polls the protected item status via Azure CLI until initial replication
# finishes. This can take anywhere from minutes to hours depending on VM
# disk size and network bandwidth.
resource "terraform_data" "wait_for_replication" {
  for_each   = var.vms
  depends_on = [module.replicate_vm]

  # Re-run the wait whenever the protected item is (re)created
  triggers_replace = module.replicate_vm[each.key].protected_item_id

  provisioner "local-exec" {
    interpreter = ["pwsh", "-Command"]
    command     = <<-EOT
      $ErrorActionPreference = 'Stop'
      $resourceId   = "${local.protected_item_ids[each.key]}"
      $vmName       = "${each.key}"
      $apiVersion   = "2024-09-01"
      $maxAttempts  = 360   # up to 6 hours with 60s intervals
      $sleepSeconds = 60

      Write-Host "Waiting for initial replication to complete for VM: $vmName..."
      Write-Host "Protected item: $resourceId"

      for ($i = 1; $i -le $maxAttempts; $i++) {
        try {
          $json = az rest --method GET `
            --url "https://management.azure.com$${resourceId}?api-version=$${apiVersion}" `
            --output json 2>&1
          $response = $json | ConvertFrom-Json
        } catch {
          Write-Host "[$vmName][$i/$maxAttempts] Failed to query status: $_  — retrying in $${sleepSeconds}s"
          Start-Sleep -Seconds $sleepSeconds
          continue
        }

        $state       = $response.properties.protectionState
        $health      = $response.properties.replicationHealth
        $allowedJobs = $response.properties.allowedJobs

        Write-Host "[$vmName][$i/$maxAttempts] State: $state | Health: $health | AllowedJobs: $($allowedJobs -join ', ')"

        # Success: replication is complete and VM is protected
        if ($allowedJobs -contains 'PlannedFailover') {
          Write-Host "`n[$vmName] Replication complete — VM is ready for migration."
          exit 0
        }

        # Also accept ProtectedItemCreated as a completed state
        if ($state -eq 'ProtectedItemCreated') {
          Write-Host "`n[$vmName] Replication complete — protected item created."
          exit 0
        }

        # Fail fast on error states
        if ($state -match 'Failed|Error') {
          Write-Host "`n[$vmName] Replication FAILED with state: $state"
          exit 1
        }

        Write-Host "  Waiting $${sleepSeconds}s before next check..."
        Start-Sleep -Seconds $sleepSeconds
      }

      Write-Host "`n[$vmName] Timeout: replication did not complete within $($maxAttempts * $sleepSeconds / 3600) hours."
      exit 1
    EOT
  }
}

# ========================================
# STEP 2: GET REPLICATION STATUS
# ========================================
# After replication is created, check the current status per VM.
module "check_status" {
  source   = "../../"
  for_each = var.vms

  location          = var.location
  name              = "e2e-check-status-${each.key}"
  parent_id         = var.parent_id
  instance_type     = var.instance_type
  operation_mode    = "get"
  project_name      = var.project_name
  protected_item_id = local.protected_item_ids[each.key]
  tags              = var.tags

  depends_on = [terraform_data.wait_for_replication]
}

# ========================================
# STEP 3: MIGRATE (Planned Failover)
# ========================================
# Automatically performs planned failover for each VM after replication
# is confirmed complete.
module "migrate_vm" {
  source   = "../../"
  for_each = var.vms

  location           = var.location
  name               = "e2e-migrate-${each.key}"
  parent_id          = var.parent_id
  instance_type      = var.instance_type
  operation_mode     = "migrate"
  protected_item_id  = local.protected_item_ids[each.key]
  shutdown_source_vm = var.shutdown_source_vm
  tags               = var.tags

  depends_on = [module.check_status]
}
