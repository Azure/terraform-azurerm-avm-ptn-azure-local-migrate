# Initialize Example

Mirrors `Initialize-AzMigrateLocalReplicationInfrastructure`. This is the
**happy-path, bare-bones** wiring: it passes the four PowerShell-equivalent
required inputs and the AVM-required `location`. Vault, cache storage account,
replication policy, replication extension, fabric IDs, and DRA identities are
auto-resolved by the module from the migrate project's Server Migration
solution.

```hcl
module "initialize_replication" {
  source = "Azure/avm-ptn-azure-local-migrate/azurerm"

  name                  = "local-migration-init"
  operation_mode        = "initialize"
  parent_id             = "/subscriptions/<sub>/resourceGroups/<rg>"
  location              = "eastus"
  project_name          = "<migrate-project>"
  source_appliance_name = "<src-appliance>"
  target_appliance_name = "<tgt-appliance>"
}
```

## Optional inputs (not shown in this example)

The following module inputs are optional. `location` is required explicitly,
even when it matches the existing migrate project's region.

| Module variable | PowerShell equivalent | Default | When to set it |
| --- | --- | --- | --- |
| `cache_storage_account_id` | `-CacheStorageAccountId` | Module reuses the solution-recorded storage account or creates one | Bring your own storage account |
| `source_machine_type` | n/a (per-cmdlet flag) | `"VMware"` | Set to `"HyperV"` for Hyper-V → Azure Local |
| `replication_policy` | `-RecoveryPointHistoryInMinutes`, `-CrashConsistentFrequencyInMinutes`, `-AppConsistentFrequencyInMinutes` | `{ recovery_point_history_minutes = 4320, crash_consistent_frequency_minutes = 60, app_consistent_frequency_minutes = 240 }` | Tune RPO / retention |
| `tags` | n/a | `{}` | Apply tags to managed resources |
| `enable_telemetry` | n/a | `true` | Disable AVM telemetry |

See the [user guide](../../docs/user-guide.md) for the full variable reference.
