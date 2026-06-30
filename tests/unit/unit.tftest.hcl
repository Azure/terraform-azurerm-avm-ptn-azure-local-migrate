# Unit tests for Azure Stack HCI Migration module
# Run with: terraform test -test-directory=tests/unit

mock_provider "azapi" {
  mock_data "azapi_resource" {
    defaults = {
      id        = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg"
      name      = "test-resource"
      parent_id = "/subscriptions/00000000-0000-0000-0000-000000000000"
      output    = "{\"properties\":{\"details\":{\"extendedDetails\":{\"vaultId\":\"/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.DataReplication/replicationVaults/test-vault\",\"sourceFabricArmId\":\"/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.DataReplication/replicationFabrics/source-fabric\",\"targetFabricArmId\":\"/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.DataReplication/replicationFabrics/target-fabric\"}}},\"location\":\"eastus\"}"
    }
  }

  mock_data "azapi_resource_list" {
    defaults = {
      id        = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg"
      parent_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg"
      output    = "{\"value\":[]}"
    }
  }

  mock_resource "azapi_resource" {
    defaults = {
      id        = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.Resources/test"
      parent_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg"
      output    = "{}"
    }
  }

  mock_resource "azapi_update_resource" {
    defaults = {
      id        = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.Resources/test"
      parent_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg"
      output    = "{}"
    }
  }
}

mock_provider "modtm" {}
mock_provider "random" {}

# ========================================
# DEFAULT VARIABLES FOR ALL TESTS
# ========================================

variables {
  name             = "test-migrate"
  parent_id        = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg"
  enable_telemetry = false
  location         = "eastus"
  project_name     = "test-project"
}

# ========================================
# OPERATION MODE TESTS
# ========================================

run "valid_operation_mode_discover" {
  command = plan

  variables {
    operation_mode = "discover"
  }

  assert {
    condition     = var.operation_mode == "discover"
    error_message = "Operation mode should be 'discover'"
  }

  assert {
    condition     = local.is_discover_mode == true
    error_message = "is_discover_mode should be true when operation_mode is 'discover'"
  }
}

run "valid_operation_mode_initialize" {
  command = plan

  variables {
    operation_mode           = "initialize"
    location                 = "eastus"
    project_name             = "test-project"
    cache_storage_account_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.Storage/storageAccounts/testsa"
  }

  assert {
    condition     = var.operation_mode == "initialize"
    error_message = "Operation mode should be 'initialize'"
  }

  assert {
    condition     = local.is_initialize_mode == true
    error_message = "is_initialize_mode should be true when operation_mode is 'initialize'"
  }
}

run "valid_operation_mode_replicate" {
  command = plan

  variables {
    operation_mode = "replicate"
  }

  assert {
    condition     = var.operation_mode == "replicate"
    error_message = "Operation mode should be 'replicate'"
  }

  assert {
    condition     = local.is_replicate_mode == true
    error_message = "is_replicate_mode should be true when operation_mode is 'replicate'"
  }
}

run "valid_operation_mode_jobs" {
  command = plan

  variables {
    operation_mode       = "jobs"
    replication_vault_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.DataReplication/replicationVaults/test-vault"
  }

  assert {
    condition     = var.operation_mode == "jobs"
    error_message = "Operation mode should be 'jobs'"
  }

  assert {
    condition     = local.is_jobs_mode == true
    error_message = "is_jobs_mode should be true when operation_mode is 'jobs'"
  }
}

run "valid_operation_mode_remove" {
  command = plan

  variables {
    operation_mode   = "remove"
    target_object_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.DataReplication/replicationVaults/test-vault/protectedItems/test-item"
  }

  assert {
    condition     = var.operation_mode == "remove"
    error_message = "Operation mode should be 'remove'"
  }

  assert {
    condition     = local.is_remove_mode == true
    error_message = "is_remove_mode should be true when operation_mode is 'remove'"
  }
}

run "valid_operation_mode_get" {
  command = plan

  variables {
    operation_mode    = "get"
    protected_item_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.DataReplication/replicationVaults/test-vault/protectedItems/test-item"
  }

  assert {
    condition     = var.operation_mode == "get"
    error_message = "Operation mode should be 'get'"
  }

  assert {
    condition     = local.is_get_mode == true
    error_message = "is_get_mode should be true when operation_mode is 'get'"
  }
}

run "valid_operation_mode_list" {
  command = plan

  variables {
    operation_mode       = "list"
    replication_vault_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.DataReplication/replicationVaults/test-vault"
  }

  assert {
    condition     = var.operation_mode == "list"
    error_message = "Operation mode should be 'list'"
  }

  assert {
    condition     = local.is_list_mode == true
    error_message = "is_list_mode should be true when operation_mode is 'list'"
  }
}

run "valid_operation_mode_migrate" {
  command = plan

  variables {
    operation_mode    = "migrate"
    protected_item_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.DataReplication/replicationVaults/test-vault/protectedItems/test-item"
  }

  # Override the protected_item_to_migrate data source so the CLI-parity
  # precondition (`PlannedFailover` in `allowedJobs`) is satisfied at plan time.
  # Mirrors the Az CLI behaviour in
  # `azext_migrate/helpers/migration/start/_validate.py`.
  override_data {
    target = data.azapi_resource.protected_item_to_migrate[0]
    values = {
      output = {
        properties = {
          allowedJobs                = ["PlannedFailover"]
          protectionState            = "Protected"
          protectionStateDescription = "Protected"
        }
      }
    }
  }

  assert {
    condition     = var.operation_mode == "migrate"
    error_message = "Operation mode should be 'migrate'"
  }

  assert {
    condition     = local.is_migrate_mode == true
    error_message = "is_migrate_mode should be true when operation_mode is 'migrate'"
  }
}

run "valid_operation_mode_create_project" {
  command = plan

  variables {
    operation_mode = "create-project"
  }

  assert {
    condition     = var.operation_mode == "create-project"
    error_message = "Operation mode should be 'create-project'"
  }

  assert {
    condition     = local.is_create_project_mode == true
    error_message = "is_create_project_mode should be true when operation_mode is 'create-project'"
  }
}

run "create_project_provisions_appliance_discovery_scaffold" {
  command = plan

  variables {
    operation_mode         = "create-project"
    create_migrate_project = true
    project_name           = "test-project"
    location               = "eastus"
    connectivity_method    = "Public-endpoint"
  }

  assert {
    condition     = length(azapi_resource.master_site) == 1
    error_message = "create-project mode should provision a master site for appliance registration"
  }

  assert {
    condition     = length(azapi_resource.discovery_server_site) == 1
    error_message = "create-project mode should provision a server discovery site bound to the discovery solution"
  }

  assert {
    condition     = azapi_resource.master_site[0].name == "test-project-mastersite"
    error_message = "master site name should be '{project_name}-mastersite'"
  }

  assert {
    condition     = azapi_resource.discovery_server_site[0].name == "test-project-serversite"
    error_message = "server site name should be '{project_name}-serversite'"
  }
}

# ========================================
# VARIABLE VALIDATION TESTS
# ========================================

run "valid_instance_type_vmware" {
  command = plan

  variables {
    operation_mode      = "discover"
    source_machine_type = "VMware"
  }

  assert {
    condition     = local.effective_instance_type == "VMwareToAzStackHCI"
    error_message = "effective_instance_type should be 'VMwareToAzStackHCI' when source_machine_type is 'VMware'"
  }

  assert {
    condition     = local.source_fabric_instance_type == "VMwareMigrate"
    error_message = "source_fabric_instance_type should be 'VMwareMigrate' for VMware source"
  }
}

run "valid_instance_type_hyperv" {
  command = plan

  variables {
    operation_mode      = "discover"
    source_machine_type = "HyperV"
  }

  assert {
    condition     = local.effective_instance_type == "HyperVToAzStackHCI"
    error_message = "effective_instance_type should be 'HyperVToAzStackHCI' when source_machine_type is 'HyperV'"
  }

  assert {
    condition     = local.source_fabric_instance_type == "HyperVMigrate"
    error_message = "source_fabric_instance_type should be 'HyperVMigrate' for HyperV source"
  }
}

run "valid_source_machine_type_vmware" {
  command = plan

  variables {
    operation_mode      = "discover"
    source_machine_type = "VMware"
  }

  assert {
    condition     = var.source_machine_type == "VMware"
    error_message = "Source machine type should be 'VMware'"
  }
}

run "valid_source_machine_type_hyperv" {
  command = plan

  variables {
    operation_mode      = "discover"
    source_machine_type = "HyperV"
  }

  assert {
    condition     = var.source_machine_type == "HyperV"
    error_message = "Source machine type should be 'HyperV'"
  }
}

# ========================================
# DEFAULT VALUES TESTS
# ========================================

run "default_values_check" {
  command = plan

  variables {
    operation_mode = "discover"
  }

  assert {
    condition     = local.effective_instance_type == "VMwareToAzStackHCI"
    error_message = "effective_instance_type should default to 'VMwareToAzStackHCI' when source_machine_type defaults to 'VMware'"
  }

  assert {
    condition     = var.source_machine_type == "VMware"
    error_message = "source_machine_type should default to 'VMware'"
  }

  assert {
    condition     = var.create_migrate_project == false
    error_message = "create_migrate_project should default to false"
  }

  assert {
    condition     = var.force_remove == false
    error_message = "force_remove should default to false"
  }

  assert {
    condition     = var.target_vm_compute.is_dynamic_memory_enabled == false
    error_message = "target_vm_compute.is_dynamic_memory_enabled should default to false"
  }

  assert {
    condition     = var.shutdown_source_vm == false
    error_message = "shutdown_source_vm should default to false"
  }
}

run "default_replication_policy_values" {
  command = plan

  variables {
    operation_mode = "discover"
  }

  assert {
    condition     = var.replication_policy.recovery_point_history_minutes == 4320
    error_message = "replication_policy.recovery_point_history_minutes should default to 4320 (72 hours)"
  }

  assert {
    condition     = var.replication_policy.crash_consistent_frequency_minutes == 60
    error_message = "replication_policy.crash_consistent_frequency_minutes should default to 60 (1 hour)"
  }

  assert {
    condition     = var.replication_policy.app_consistent_frequency_minutes == 240
    error_message = "replication_policy.app_consistent_frequency_minutes should default to 240 (4 hours)"
  }
}

run "default_vm_values" {
  command = plan

  variables {
    operation_mode = "discover"
  }

  assert {
    condition     = var.target_vm_compute.cpu_cores == 2
    error_message = "target_vm_compute.cpu_cores should default to 2"
  }

  assert {
    condition     = var.target_vm_compute.ram_mb == 4096
    error_message = "target_vm_compute.ram_mb should default to 4096"
  }
}

# ========================================
# FABRIC INSTANCE TYPE TESTS
# ========================================

run "target_fabric_instance_type_always_azstackhci" {
  command = plan

  variables {
    operation_mode      = "discover"
    source_machine_type = "VMware"
  }

  assert {
    condition     = local.target_fabric_instance_type == "AzStackHCI"
    error_message = "target_fabric_instance_type should always be 'AzStackHCI'"
  }
}

run "target_fabric_instance_type_hyperv_also_azstackhci" {
  command = plan

  variables {
    operation_mode      = "discover"
    source_machine_type = "HyperV"
  }

  assert {
    condition     = local.target_fabric_instance_type == "AzStackHCI"
    error_message = "target_fabric_instance_type should always be 'AzStackHCI' even for HyperV source"
  }
}

# ========================================
# VALIDATION ERROR TESTS
# ========================================

run "invalid_operation_mode" {
  command = plan

  variables {
    operation_mode = "invalid_mode"
  }

  expect_failures = [var.operation_mode]
}

run "invalid_source_machine_type" {
  command = plan

  variables {
    operation_mode      = "discover"
    source_machine_type = "Invalid"
  }

  expect_failures = [var.source_machine_type]
}

run "invalid_parent_id_format" {
  command = plan

  variables {
    operation_mode = "discover"
    parent_id      = "not-a-valid-resource-id"
  }

  expect_failures = [var.parent_id]
}

run "invalid_name_too_short" {
  command = plan

  variables {
    name           = "a"
    operation_mode = "discover"
  }

  expect_failures = [var.name]
}

run "invalid_lock_kind" {
  command = plan

  variables {
    operation_mode = "discover"
    lock = {
      kind = "InvalidLock"
    }
  }

  expect_failures = [var.lock]
}

# ========================================
# CACHE STORAGE ACCOUNT RESOLUTION TESTS
# Verifies fix for duplicate storage-account creation when the migrate project's
# Server Migration solution already has a replicationStorageAccountId recorded.
# ========================================

# Case 1: caller passes an explicit cache_storage_account_id.
# Module must NOT create a new storage account and resolved id must equal the input.
run "cache_storage_account_explicit_var_wins" {
  command = plan

  variables {
    operation_mode           = "initialize"
    location                 = "eastus"
    project_name             = "test-project"
    source_appliance_name    = "src-appl"
    target_appliance_name    = "tgt-appl"
    cache_storage_account_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.Storage/storageAccounts/usersa"
  }

  assert {
    condition     = local.resolved_cache_storage_account_id == "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.Storage/storageAccounts/usersa"
    error_message = "resolved_cache_storage_account_id should equal var.cache_storage_account_id when supplied"
  }

  assert {
    condition     = length(azapi_resource.cache_storage_account) == 0
    error_message = "cache_storage_account must NOT be planned when caller supplies cache_storage_account_id"
  }
}

# Case 2: no caller id, no existing storage account in solution.
# Module MUST create a new storage account (count = 1).
run "cache_storage_account_created_when_none_exists" {
  command = plan

  variables {
    operation_mode        = "initialize"
    location              = "eastus"
    project_name          = "test-project"
    source_appliance_name = "src-appl"
    target_appliance_name = "tgt-appl"
  }

  assert {
    condition     = local.has_existing_replication_storage_account == false
    error_message = "Default mock should not expose an existing replicationStorageAccountId"
  }

  assert {
    condition     = length(azapi_resource.cache_storage_account) == 1
    error_message = "cache_storage_account must be planned when neither caller id nor solution-recorded id exists"
  }
}

# Case 3: solution already records a replicationStorageAccountId.
# Module MUST reuse it and NOT plan a duplicate (fixes the reported regression).
run "cache_storage_account_reused_from_solution" {
  command = plan

  # Override the replication_solution data so its extendedDetails carry an
  # existing replicationStorageAccountId. We intentionally omit vaultId here
  # to keep vault_exists_in_solution false and avoid pulling in unrelated
  # vault-lookup paths that aren't exercised by this scenario.
  override_data {
    target = data.azapi_resource.replication_solution[0]
    values = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.Migrate/migrateprojects/test-project/solutions/Servers-Migration-ServerMigration_DataReplication"
      output = {
        properties = {
          details = {
            extendedDetails = {
              replicationStorageAccountId = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.Storage/storageAccounts/existingmigratersa"
            }
          }
        }
      }
    }
  }

  variables {
    operation_mode        = "initialize"
    location              = "eastus"
    project_name          = "test-project"
    source_appliance_name = "src-appl"
    target_appliance_name = "tgt-appl"
  }

  assert {
    condition     = local.has_existing_replication_storage_account == true
    error_message = "has_existing_replication_storage_account should be true when solution.extendedDetails has replicationStorageAccountId"
  }

  assert {
    condition     = local.resolved_cache_storage_account_id == "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.Storage/storageAccounts/existingmigratersa"
    error_message = "resolved_cache_storage_account_id should reuse the existing replicationStorageAccountId from the solution"
  }

  assert {
    condition     = length(azapi_resource.cache_storage_account) == 0
    error_message = "cache_storage_account must NOT be planned when the solution already records a replicationStorageAccountId (fix for duplicate-creation bug)"
  }
}

# ========================================
# AVM INTERFACE WIRING TESTS
# ========================================

# tags should propagate to the migrate project when create-project mode creates one.
run "tags_propagate_to_migrate_project" {
  command = plan

  variables {
    operation_mode         = "create-project"
    location               = "eastus"
    project_name           = "test-project"
    create_migrate_project = true
    tags = {
      env   = "test"
      owner = "avm"
    }
  }

  assert {
    condition     = azapi_resource.migrate_project[0].tags["env"] == "test" && azapi_resource.migrate_project[0].tags["owner"] == "avm"
    error_message = "var.tags must propagate to the migrate project"
  }
}

# tags should propagate to the replication vault and cache storage account in initialize mode.
run "tags_propagate_to_vault_and_storage" {
  command = plan

  variables {
    operation_mode        = "initialize"
    location              = "eastus"
    project_name          = "test-project"
    source_appliance_name = "src-appl"
    target_appliance_name = "tgt-appl"
    tags = {
      env   = "test"
      owner = "avm"
    }
  }

  assert {
    condition     = azapi_resource.replication_vault[0].tags["env"] == "test"
    error_message = "var.tags must propagate to the replication vault"
  }

  assert {
    condition     = azapi_resource.cache_storage_account[0].tags["owner"] == "avm"
    error_message = "var.tags must propagate to the cache storage account"
  }
}

# diagnostic_settings should create one azapi diagnosticSettings resource per map entry,
# scoped to the replication vault.
run "diagnostic_settings_create_one_per_entry" {
  command = plan

  variables {
    operation_mode        = "initialize"
    location              = "eastus"
    project_name          = "test-project"
    source_appliance_name = "src-appl"
    target_appliance_name = "tgt-appl"
    diagnostic_settings = {
      to_law = {
        name                  = "send-to-law"
        workspace_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.OperationalInsights/workspaces/test-law"
      }
    }
  }

  assert {
    condition     = length(azapi_resource.diagnostic_setting) == 1
    error_message = "diagnostic_settings must produce one azapi_resource.diagnostic_setting per map entry"
  }

  assert {
    condition     = azapi_resource.diagnostic_setting["to_law"].name == "send-to-law"
    error_message = "diagnostic_setting name must come from each.value.name when supplied"
  }

  assert {
    condition     = azapi_resource.diagnostic_setting["to_law"].type == "Microsoft.Insights/diagnosticSettings@2021-05-01-preview"
    error_message = "diagnostic_setting must use the Microsoft.Insights/diagnosticSettings type"
  }
}

# Requesting diagnostic_settings without a resolvable vault (e.g. discover mode with no
# replication_vault_id) must fail the precondition rather than silently succeeding.
run "diagnostic_settings_require_vault" {
  command = plan

  variables {
    operation_mode = "discover"
    diagnostic_settings = {
      to_law = {
        workspace_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.OperationalInsights/workspaces/test-law"
      }
    }
  }

  expect_failures = [azapi_resource.diagnostic_setting]
}

# ========================================
# LOCATION AUTO-DISCOVERY TESTS
# ========================================

# Caller-supplied `var.location` always wins, even when the existing project
# advertises a different region. This preserves the explicit-override contract.
run "location_explicit_var_wins_over_project" {
  command = plan

  override_data {
    target = data.azapi_resource.migrate_project_existing[0]
    values = {
      id       = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.Migrate/migrateprojects/test-project"
      location = "westeurope"
    }
  }

  variables {
    operation_mode = "discover"
    location       = "eastus"
    project_name   = "test-project"
  }

  assert {
    condition     = local.effective_location == "eastus"
    error_message = "Caller-supplied var.location must take precedence over the discovered project location"
  }
}

# When `var.location` is omitted, the module reads the region from the existing
# migrate project (PowerShell-equivalent behaviour).
run "location_auto_discovered_from_project" {
  command = plan

  override_data {
    target = data.azapi_resource.migrate_project_existing[0]
    values = {
      id       = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.Migrate/migrateprojects/test-project"
      location = "westeurope"
    }
  }

  variables {
    operation_mode = "discover"
    location       = null
    project_name   = "test-project"
  }

  assert {
    condition     = local.effective_location == "westeurope"
    error_message = "effective_location must auto-discover from the migrate project when var.location is null"
  }
}

# Creating a new migrate project has no existing project to discover from,
# so the precondition must fail when var.location is omitted.
run "location_required_when_creating_project" {
  command = plan

  variables {
    operation_mode         = "create-project"
    location               = null
    project_name           = "new-project"
    create_migrate_project = true
  }

  expect_failures = [azapi_resource.migrate_project]
}

# ========================================
# BROWNFIELD ROLE-ASSIGNMENT DEDUP
# ========================================
# When the cache storage account is auto-discovered from the migrate project's
# replication solution (not supplied via var.cache_storage_account_id), the
# module must still inspect the existing role assignments and dedup against
# them. Without this, re-running `initialize` against an already-initialized
# project produces six RoleAssignmentExists 409s.
run "brownfield_role_assignment_lookup_when_storage_auto_discovered" {
  command = plan

  override_data {
    target = data.azapi_resource.replication_solution[0]
    values = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.Migrate/migrateprojects/test-project/solutions/Servers-Migration-ServerMigration_DataReplication"
      output = {
        properties = {
          details = {
            extendedDetails = {
              replicationStorageAccountId = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.Storage/storageAccounts/autosa"
            }
          }
        }
      }
    }
  }

  variables {
    operation_mode        = "initialize"
    location              = "eastus"
    project_name          = "test-project"
    source_appliance_name = "src-appl"
    target_appliance_name = "tgt-appl"
  }

  assert {
    condition     = length(data.azapi_resource_list.cache_storage_role_assignments) == 1
    error_message = "cache_storage_role_assignments lookup must fire when storage account is auto-discovered from the solution (not just when var.cache_storage_account_id is set)"
  }

  assert {
    condition     = data.azapi_resource_list.cache_storage_role_assignments[0].parent_id == "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.Storage/storageAccounts/autosa"
    error_message = "cache_storage_role_assignments parent_id must point at the auto-discovered storage account"
  }
}

# ========================================
# RUN-AS ACCOUNT AUTO-DISCOVERY
# ========================================
# Caller-supplied `var.run_as_account_id` always wins (explicit override).
run "run_as_account_id_explicit_var_wins" {
  command = plan

  variables {
    operation_mode       = "replicate"
    location             = "eastus"
    project_name         = "test-project"
    replication_vault_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.DataReplication/replicationVaults/test-vault"
    source_machine_type  = "VMware"
    machine_id           = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.OffAzure/VMwareSites/src-appl/machines/vm-1"
    run_as_account_id    = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.OffAzure/VMwareSites/src-appl/runasaccounts/explicit-uuid"
  }

  assert {
    condition     = local.effective_run_as_account_id == "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.OffAzure/VMwareSites/src-appl/runasaccounts/explicit-uuid"
    error_message = "var.run_as_account_id must take precedence over auto-discovery"
  }
}

# VMware path: machine.properties.vCenterId -> GET vCenter -> properties.runAsAccountId.
# Mirrors Az CLI `_process_inputs.py`.
run "run_as_account_id_auto_discovered_from_vcenter" {
  command = plan

  override_data {
    target = data.azapi_resource.replicate_machine[0]
    values = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.OffAzure/VMwareSites/src-appl/machines/vm-1"
      output = {
        properties = {
          vCenterId = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.OffAzure/VMwareSites/src-appl/vCenters/vcenter-1"
        }
      }
    }
  }

  override_data {
    target = data.azapi_resource.machine_parent_for_run_as[0]
    values = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.OffAzure/VMwareSites/src-appl/vCenters/vcenter-1"
      output = {
        properties = {
          runAsAccountId = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.OffAzure/VMwareSites/src-appl/runasaccounts/discovered-vmware-uuid"
        }
      }
    }
  }

  variables {
    operation_mode       = "replicate"
    location             = "eastus"
    project_name         = "test-project"
    replication_vault_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.DataReplication/replicationVaults/test-vault"
    source_machine_type  = "VMware"
    machine_id           = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.OffAzure/VMwareSites/src-appl/machines/vm-1"
  }

  assert {
    condition     = local.machine_parent_type == "Microsoft.OffAzure/VMwareSites/vCenters@2023-06-06"
    error_message = "machine_parent_type must select the VMware vCenter ARM type when machine.properties.vCenterId is populated"
  }

  assert {
    condition     = local.effective_run_as_account_id == "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.OffAzure/VMwareSites/src-appl/runasaccounts/discovered-vmware-uuid"
    error_message = "effective_run_as_account_id must equal the vCenter's runAsAccountId when var.run_as_account_id is unset"
  }
}

# Hyper-V standalone path: machine.properties.hostId -> GET host -> properties.runAsAccountId.
run "run_as_account_id_auto_discovered_from_hyperv_host" {
  command = plan

  override_data {
    target = data.azapi_resource.replicate_machine[0]
    values = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.OffAzure/HyperVSites/src-appl/machines/vm-1"
      output = {
        properties = {
          hostId = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.OffAzure/HyperVSites/src-appl/hosts/host-1"
        }
      }
    }
  }

  override_data {
    target = data.azapi_resource.machine_parent_for_run_as[0]
    values = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.OffAzure/HyperVSites/src-appl/hosts/host-1"
      output = {
        properties = {
          runAsAccountId = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.OffAzure/HyperVSites/src-appl/runasaccounts/discovered-hyperv-uuid"
        }
      }
    }
  }

  variables {
    operation_mode       = "replicate"
    location             = "eastus"
    project_name         = "test-project"
    replication_vault_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.DataReplication/replicationVaults/test-vault"
    source_machine_type  = "HyperV"
    machine_id           = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.OffAzure/HyperVSites/src-appl/machines/vm-1"
  }

  assert {
    condition     = local.machine_parent_type == "Microsoft.OffAzure/HyperVSites/hosts@2023-06-06"
    error_message = "machine_parent_type must select the Hyper-V host ARM type when machine.properties.hostId is populated"
  }

  assert {
    condition     = local.effective_run_as_account_id == "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.OffAzure/HyperVSites/src-appl/runasaccounts/discovered-hyperv-uuid"
    error_message = "effective_run_as_account_id must equal the host's runAsAccountId when var.run_as_account_id is unset"
  }
}

# ========================================
# CUSTOM LOCATION REGION AUTO-DISCOVERY
# ========================================
# The protected item's `customLocationRegion` must be the customLocation
# resource's actual region (where the HCI cluster lives), NOT the migrate
# project's region. Mirrors Az CLI
# `helpers/replication/new/_execute_new.get_ARC_resource_bridge_info`.
run "custom_location_region_auto_discovered" {
  command = plan

  override_data {
    target = data.azapi_resource.custom_location[0]
    values = {
      id       = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/cluster-rg/providers/Microsoft.ExtendedLocation/customLocations/cl-1"
      location = "eastus"
      output = {
        location = "eastus"
      }
    }
  }

  variables {
    operation_mode       = "replicate"
    location             = "centralus"
    project_name         = "test-project"
    replication_vault_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.DataReplication/replicationVaults/test-vault"
    source_machine_type  = "VMware"
    machine_id           = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.OffAzure/VMwareSites/src-appl/machines/vm-1"
    custom_location_id   = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/cluster-rg/providers/Microsoft.ExtendedLocation/customLocations/cl-1"
  }

  assert {
    condition     = local.effective_custom_location_region == "eastus"
    error_message = "effective_custom_location_region must resolve to the customLocation resource's location, not the migrate project's location (would otherwise cause LocationNotAvailableForResourceType on Microsoft.AzureStackHCI/virtualHardDisks)"
  }

  assert {
    condition     = local.effective_location == "centralus"
    error_message = "effective_location should still reflect the migrate project's region (used for other resources)"
  }
}

# Fallback: when no custom_location_id is supplied, customLocationRegion
# preserves prior behaviour and falls back to the migrate project's region.
run "custom_location_region_falls_back_to_project_region" {
  command = plan

  variables {
    operation_mode       = "replicate"
    location             = "eastus"
    project_name         = "test-project"
    replication_vault_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.DataReplication/replicationVaults/test-vault"
    source_machine_type  = "VMware"
    machine_id           = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.OffAzure/VMwareSites/src-appl/machines/vm-1"
  }

  assert {
    condition     = local.effective_custom_location_region == "eastus"
    error_message = "effective_custom_location_region must fall back to effective_location when no custom_location_id is supplied"
  }
}

# ========================================
# MIGRATE-MODE STATE VALIDATION (CLI parity)
# ========================================
# The CLI's `validate_protected_item_for_migration` refuses to call /plannedFailover
# unless `PlannedFailover` or `Restart` is in `allowedJobs`. The module mirrors
# this via a lifecycle.precondition on the planned_failover resources.
run "migrate_precondition_rejects_already_failed_over_item" {
  command = plan

  override_data {
    target = data.azapi_resource.protected_item_to_migrate[0]
    values = {
      output = {
        properties = {
          allowedJobs                = ["CommitFailover", "DisableProtection"]
          protectionState            = "PlannedFailoverCompleted"
          protectionStateDescription = "Planned failover completed"
        }
      }
    }
  }

  variables {
    operation_mode    = "migrate"
    protected_item_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.DataReplication/replicationVaults/test-vault/protectedItems/test-item"
  }

  expect_failures = [azapi_resource_action.planned_failover_vmware]
}

# Allowed jobs containing `Restart` (the CLI also accepts this) must satisfy
# the precondition.
run "migrate_precondition_accepts_restart_state" {
  command = plan

  override_data {
    target = data.azapi_resource.protected_item_to_migrate[0]
    values = {
      output = {
        properties = {
          allowedJobs                = ["Restart"]
          protectionState            = "PlannedFailoverFailed"
          protectionStateDescription = "Planned failover failed (retryable)"
        }
      }
    }
  }

  variables {
    operation_mode      = "migrate"
    source_machine_type = "VMware"
    protected_item_id   = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.DataReplication/replicationVaults/test-vault/protectedItems/test-item"
  }

  assert {
    condition     = local.protected_item_is_migratable == true
    error_message = "protected_item_is_migratable must be true when allowedJobs contains 'Restart' (CLI parity)"
  }
}

