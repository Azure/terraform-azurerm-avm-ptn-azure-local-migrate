# Replicate Example

Mirrors `New-AzMigrateLocalServerReplication` (Option 1, "ByIdDefaultUser"). This is the **happy-path, bare-bones** wiring: only the PowerShell-equivalent required inputs are passed. Replication policy, replication extension, fabric agents, instance type, and source/target fabric IDs are all auto-resolved by the module.

## Prerequisites

1. An Azure Migrate project with discovery completed.
2. Replication infrastructure initialized — see the [initialize example](../initialize/README.md).
3. Target Azure Stack HCI cluster registered with Arc and a custom location configured.

```hcl
module "replicate_vm" {
  source = "Azure/avm-ptn-azure-local-migrate/azurerm"

  name           = "vm-replication"
  operation_mode = "replicate"
  parent_id      = "/subscriptions/<sub>/resourceGroups/<rg>"
  project_name   = "<migrate-project>"

  machine_id               = "/subscriptions/.../machines/<vm-id>"
  os_disk_id               = "scsi0:0"
  source_appliance_name    = "<src-appliance>"
  target_appliance_name    = "<tgt-appliance>"
  target_resource_group_id = "/subscriptions/.../resourceGroups/<target-rg>"
  target_storage_path_id   = "/subscriptions/.../storagecontainers/<csv>"
  target_virtual_switch_id = "/subscriptions/.../logicalnetworks/<switch>"
  target_vm_name           = "migrated-vm-01"

  custom_location_id    = "/subscriptions/.../customLocations/<cl>"
  target_hci_cluster_id = "/subscriptions/.../clusters/<hci>"
}
```

## Optional inputs (not shown in this example)

These root-module variables are not required for the happy path. Set them
only when you need to deviate from defaults.

| Module variable | PowerShell equivalent | Default | When to set it |
| --- | --- | --- | --- |
| `location` | n/a (auto-resolved by cmdlet) | Auto-discovered from the existing migrate project | Override when the project's region is unavailable |
| `target_vm_compute` | `-TargetVMCPUCore`, `-TargetVMRam`, `-IsDynamicMemoryEnabled` | `{ cpu_cores = 2, ram_mb = 4096, is_dynamic_memory_enabled = false }` | Right-size the target VM |
| `run_as_account_id` | `-RunAsAccountID` | `null` | Appliance needs an explicit run-as account |
| `source_machine_type` | n/a (per-cmdlet flag) | `"VMware"` | Set to `"HyperV"` for Hyper-V → Azure Local |
| `disks_to_include` | `-DiskToInclude` (power-user mode) | `[]` | Replace simple `os_disk_id` mode with explicit multi-disk config |
| `nics_to_include` | `-NicToInclude` (power-user mode) | `[]` | Replace simple `target_virtual_switch_id` mode with explicit multi-NIC config |
| `replication_policy` | `-RecoveryPointHistoryInMinutes`, `-CrashConsistentFrequencyInMinutes`, `-AppConsistentFrequencyInMinutes` | `{ recovery_point_history_minutes = 4320, crash_consistent_frequency_minutes = 60, app_consistent_frequency_minutes = 240 }` | Tune RPO / retention |
| `tags` | n/a | `{}` | Apply tags to managed resources |
| `enable_telemetry` | n/a | `true` | Disable AVM telemetry |

## Finding required values

```bash
# Discovered machines for the source appliance
az rest --method GET \
  --uri "https://management.azure.com/subscriptions/<sub>/resourceGroups/<rg>/providers/Microsoft.OffAzure/VMwareSites/<site>/machines?api-version=2023-06-06"

# Storage containers (target storage paths) on the HCI cluster
az rest --method GET \
  --uri "https://management.azure.com/subscriptions/<sub>/resourceGroups/<rg>/providers/Microsoft.AzureStackHCI/storagecontainers?api-version=2024-01-01"

# Logical networks (target virtual switches)
az rest --method GET \
  --uri "https://management.azure.com/subscriptions/<sub>/resourceGroups/<rg>/providers/Microsoft.AzureStackHCI/logicalnetworks?api-version=2024-01-01"
```

See the [user guide](../../docs/user-guide.md) for the full variable reference.
