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

# ========================================
# VARIABLE VALIDATION TESTS
# ========================================

run "valid_hyperv_generation_1" {
  command = plan

  variables {
    operation_mode    = "discover"
    hyperv_generation = "1"
  }

  assert {
    condition     = var.hyperv_generation == "1"
    error_message = "HyperV generation should be '1'"
  }
}

run "valid_hyperv_generation_2" {
  command = plan

  variables {
    operation_mode    = "discover"
    hyperv_generation = "2"
  }

  assert {
    condition     = var.hyperv_generation == "2"
    error_message = "HyperV generation should be '2'"
  }
}

run "valid_instance_type_vmware" {
  command = plan

  variables {
    operation_mode = "discover"
    instance_type  = "VMwareToAzStackHCI"
  }

  assert {
    condition     = var.instance_type == "VMwareToAzStackHCI"
    error_message = "Instance type should be 'VMwareToAzStackHCI'"
  }

  assert {
    condition     = local.source_fabric_instance_type == "VMwareMigrate"
    error_message = "source_fabric_instance_type should be 'VMwareMigrate' for VMwareToAzStackHCI"
  }
}

run "valid_instance_type_hyperv" {
  command = plan

  variables {
    operation_mode = "discover"
    instance_type  = "HyperVToAzStackHCI"
  }

  assert {
    condition     = var.instance_type == "HyperVToAzStackHCI"
    error_message = "Instance type should be 'HyperVToAzStackHCI'"
  }

  assert {
    condition     = local.source_fabric_instance_type == "HyperVMigrate"
    error_message = "source_fabric_instance_type should be 'HyperVMigrate' for HyperVToAzStackHCI"
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
    condition     = var.hyperv_generation == "1"
    error_message = "hyperv_generation should default to '1'"
  }

  assert {
    condition     = var.instance_type == "VMwareToAzStackHCI"
    error_message = "instance_type should default to 'VMwareToAzStackHCI'"
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
    condition     = var.is_dynamic_memory_enabled == false
    error_message = "is_dynamic_memory_enabled should default to false"
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
    condition     = var.recovery_point_history_minutes == 4320
    error_message = "recovery_point_history_minutes should default to 4320 (72 hours)"
  }

  assert {
    condition     = var.crash_consistent_frequency_minutes == 60
    error_message = "crash_consistent_frequency_minutes should default to 60 (1 hour)"
  }

  assert {
    condition     = var.app_consistent_frequency_minutes == 240
    error_message = "app_consistent_frequency_minutes should default to 240 (4 hours)"
  }
}

run "default_vm_values" {
  command = plan

  variables {
    operation_mode = "discover"
  }

  assert {
    condition     = var.source_vm_cpu_cores == 2
    error_message = "source_vm_cpu_cores should default to 2"
  }

  assert {
    condition     = var.source_vm_ram_mb == 4096
    error_message = "source_vm_ram_mb should default to 4096"
  }

  assert {
    condition     = var.os_disk_size_gb == 60
    error_message = "os_disk_size_gb should default to 60"
  }
}

# ========================================
# FABRIC INSTANCE TYPE TESTS
# ========================================

run "target_fabric_instance_type_always_azstackhci" {
  command = plan

  variables {
    operation_mode = "discover"
    instance_type  = "VMwareToAzStackHCI"
  }

  assert {
    condition     = local.target_fabric_instance_type == "AzStackHCI"
    error_message = "target_fabric_instance_type should always be 'AzStackHCI'"
  }
}

run "target_fabric_instance_type_hyperv_also_azstackhci" {
  command = plan

  variables {
    operation_mode = "discover"
    instance_type  = "HyperVToAzStackHCI"
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

run "invalid_hyperv_generation" {
  command = plan

  variables {
    operation_mode    = "discover"
    hyperv_generation = "3"
  }

  expect_failures = [var.hyperv_generation]
}

run "invalid_instance_type" {
  command = plan

  variables {
    operation_mode = "discover"
    instance_type  = "InvalidType"
  }

  expect_failures = [var.instance_type]
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
