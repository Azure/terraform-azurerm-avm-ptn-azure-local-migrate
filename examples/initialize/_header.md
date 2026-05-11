# Initialize Example

Mirrors `Initialize-AzMigrateLocalReplicationInfrastructure`. This is the
**happy-path, bare-bones** wiring: only the four PowerShell-equivalent
required inputs are passed. Vault, cache storage account, replication
policy, replication extension, fabric IDs, and DRA identities are all
auto-resolved by the module from the migrate project's Server Migration
solution.

```hcl
module "initialize_replication" {
  source = "Azure/avm-ptn-azure-local-migrate/azurerm"

  location              = "eastus"
  name                  = "local-migration-init"
  operation_mode        = "initialize"
  parent_id             = "/subscriptions/<sub>/resourceGroups/<rg>"
  project_name          = "<migrate-project>"
  source_appliance_name = "<src-appliance>"
  target_appliance_name = "<tgt-appliance>"
}
```

## Optional inputs (not shown in this example)

These root-module variables are not required for the happy path. Set them
only when you need to deviate from defaults.

| Module variable | PowerShell equivalent | Default | When to set it |
| --- | --- | --- | --- |
| `cache_storage_account_id` | `-CacheStorageAccountId` | Module reuses the solution-recorded storage account or creates one | Bring your own storage account |
| `source_machine_type` | n/a (per-cmdlet flag) | `"VMware"` | Set to `"HyperV"` for Hyper-V → Azure Local |
| `replication_policy` | `-RecoveryPointHistoryInMinutes`, `-CrashConsistentFrequencyInMinutes`, `-AppConsistentFrequencyInMinutes` | `{ recovery_point_history_minutes = 4320, crash_consistent_frequency_minutes = 60, app_consistent_frequency_minutes = 240 }` | Tune RPO / retention |
| `tags` | n/a | `{}` | Apply tags to managed resources |
| `enable_telemetry` | n/a | `true` | Disable AVM telemetry |

See the [user guide](../../docs/user-guide.md) for the full variable reference.
