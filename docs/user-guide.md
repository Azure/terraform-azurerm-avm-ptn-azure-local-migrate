# User Guide: Azure Local Migrate Terraform Module

> **terraform-azurerm-avm-ptn-azure-local-migrate**
>
> Terraform Registry: <https://registry.terraform.io/modules/Azure/avm-ptn-azure-local-migrate/azurerm/latest>

This guide walks you through using the Azure Verified Module (AVM) for Azure Migrate to discover, replicate, and migrate virtual machines from VMware or Hyper-V environments to Azure Stack HCI using Terraform.

---

## Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Operation Modes](#operation-modes)
  - [1. Create Project](#1-create-project)
  - [2. Discover Servers](#2-discover-servers)
  - [3. Initialize Replication Infrastructure](#3-initialize-replication-infrastructure)
  - [4. Replicate VMs](#4-replicate-vms)
  - [5. Monitor Replication Jobs](#5-monitor-replication-jobs)
  - [6. List Protected Items](#6-list-protected-items)
  - [7. Get Protected Item Details](#7-get-protected-item-details)
  - [8. Migrate (Planned Failover)](#8-migrate-planned-failover)
  - [9. Remove Replication](#9-remove-replication)
- [End-to-End Migration](#end-to-end-migration)
- [Configuration Modes](#configuration-modes)
  - [Default User Mode](#default-user-mode)
  - [Power User Mode](#power-user-mode)
- [Supported Migration Paths](#supported-migration-paths)
- [Variable Reference](#variable-reference)
- [Output Reference](#output-reference)
- [Brownfield Support](#brownfield-support)
- [Troubleshooting](#troubleshooting)
- [FAQ](#faq)

---

## Overview

This module automates the full lifecycle of VM migration to Azure Stack HCI through Azure Migrate. It uses the [AzAPI Terraform provider](https://registry.terraform.io/providers/Azure/azapi/latest) to interact directly with Azure Resource Manager APIs, enabling a declarative, repeatable migration workflow.

The module operates in **9 distinct modes**, each representing a step in the migration journey. You control which operation runs by setting the `operation_mode` variable.

### Key Capabilities

- **Create** Azure Migrate projects with all required solutions
- **Discover** VMs from VMware vCenter or Hyper-V hosts
- **Initialize** replication infrastructure (vaults, policies, extensions, storage accounts)
- **Replicate** VMs to Azure Stack HCI with full disk and NIC configuration
- **Monitor** replication jobs and health status
- **Migrate** VMs via planned failover with optional source VM shutdown
- **Remove** replication when no longer needed
- **Brownfield support** — safely integrates with existing Azure Migrate setups

---

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     Azure Migrate Project                    │
│  ┌──────────────┐ ┌──────────────┐ ┌──────────────────────┐ │
│  │  Assessment   │ │  Discovery   │ │  Migration Solution  │ │
│  │  Solution     │ │  Solution    │ │  + DataReplication   │ │
│  └──────────────┘ └──────────────┘ └───────────┬──────────┘ │
└────────────────────────────────────────────────┼────────────┘
                                                 │
                    ┌────────────────────────────┤
                    ▼                            ▼
         ┌──────────────────┐         ┌───────────────────┐
         │ Replication Vault │         │  Cache Storage    │
         │ (SystemAssigned  │         │  Account          │
         │  Managed Identity)│         │  (Standard_LRS)   │
         └────────┬─────────┘         └───────────────────┘
                  │
     ┌────────────┼────────────┐
     ▼            ▼            ▼
┌──────────┐ ┌──────────┐ ┌───────────────┐
│Replication│ │Replication│ │  Protected    │
│  Policy   │ │ Extension │ │  Items (VMs)  │
└──────────┘ └──────────┘ └───────────────┘
                  │
        ┌─────────┴─────────┐
        ▼                   ▼
  ┌───────────┐      ┌───────────┐
  │  Source    │      │  Target   │
  │  Fabric   │      │  Fabric   │
  │ (VMware/  │      │(AzStackHCI│
  │  HyperV)  │      │  )        │
  └───────────┘      └───────────┘
```

---

## Prerequisites

### Software Requirements

| Requirement | Version |
|---|---|
| Terraform | >= 1.9, < 2.0 |
| AzAPI Provider | ~> 2.4 |
| Azure CLI | Latest (for authentication & the end-to-end polling script) |

### Azure Requirements

1. **Azure subscription** with permissions to create resources (Contributor or Owner role)
2. **Resource group** — must already exist before using this module
3. **Azure Migrate appliance** — deployed and registered in your source environment (VMware vCenter or Hyper-V host)
4. **Azure Stack HCI cluster** — deployed, registered, and configured as a migration target
5. **Custom location** — configured on your Azure Stack HCI cluster
6. **Network connectivity** — between source appliance, Azure, and target HCI cluster

### Information You Will Need

Before starting, gather these resource identifiers:

| Item | Where to Find It |
|---|---|
| Resource Group ID | Azure Portal > Resource Groups > Properties |
| Azure Migrate Project Name | Azure Portal > Azure Migrate > Project name |
| Source Appliance Name | Azure Migrate > Discovered items > Appliance name |
| Target Appliance Name | Azure Migrate > Azure Stack HCI > Appliance name |
| Custom Location ID | Azure Portal > Azure Stack HCI > Custom locations |
| Target HCI Cluster ID | Azure Portal > Azure Stack HCI > Clusters > Properties |
| Target Resource Group ID | The resource group on the target subscription for migrated VMs |
| Target Storage Path ID | Azure Stack HCI > Storage containers |
| Target Virtual Switch ID | Azure Stack HCI > Logical networks |

---

## Quick Start

### 1. Configure the Provider

```hcl
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
```

### 2. Add the Module from the Registry

```hcl
module "migrate" {
  source  = "Azure/avm-ptn-azure-local-migrate/azurerm"
  version = "~> 0.1"  # Pin to the latest compatible version

  # ... configuration ...
}
```

> Find the latest version at: <https://registry.terraform.io/modules/Azure/avm-ptn-azure-local-migrate/azurerm/latest>

### 3. Authenticate

```bash
az login
az account set --subscription "<your-subscription-id>"
```

### 4. Use the Module

Each step in the migration requires a separate module invocation with a different `operation_mode`. See the detailed sections below.

---

## Operation Modes

The module's behavior is entirely controlled by the `operation_mode` variable. Valid values are:

| Mode | Description |
|---|---|
| `create-project` | Create a new Azure Migrate project with all solutions |
| `discover` | List discovered VMs from the source environment |
| `initialize` | Set up replication vault, policy, extension, and storage |
| `replicate` | Start replication for a specific VM |
| `jobs` | Query replication job status |
| `list` | List all protected (replicating) items in a vault |
| `get` | Get detailed status of a specific protected item |
| `migrate` | Perform planned failover (final migration) |
| `remove` | Disable and remove replication for a protected item |

---

### 1. Create Project

Creates a new Azure Migrate project with the four required solutions (Assessment, Discovery, Migration, DataReplication) and assigns the necessary role to the project's managed identity.

```hcl
module "create_project" {
  source  = "Azure/avm-ptn-azure-local-migrate/azurerm"
  version = "~> 0.1"

  location               = "eastus"
  name                   = "create-project"
  parent_id              = "/subscriptions/<sub-id>/resourceGroups/<rg-name>"
  create_migrate_project = true
  operation_mode         = "create-project"
  project_name           = "my-migrate-project"
  tags = {
    Environment = "Production"
  }
}
```

**Key inputs:**
- `create_migrate_project` — Must be `true`
- `project_name` — The name for the new Azure Migrate project

**Key outputs:**
- `migrate_project_id` — The ARM resource ID of the created project

> **Note:** Skip this step if you already have an Azure Migrate project. The module can work with existing projects.

---

### 2. Discover Servers

Queries Azure Migrate to list all discovered VMs in your source environment. This is a read-only operation that retrieves server metadata (machine name, IP addresses, OS, boot type, disk IDs).

```hcl
module "discover" {
  source  = "Azure/avm-ptn-azure-local-migrate/azurerm"
  version = "~> 0.1"

  location       = "eastus"
  name           = "discover"
  parent_id      = "/subscriptions/<sub-id>/resourceGroups/<rg-name>"
  operation_mode = "discover"
  project_name   = "my-migrate-project"
  instance_type  = "VMwareToAzStackHCI"
}
```

**Optional inputs:**
- `appliance_name` — Filter by specific appliance (site). If omitted, discovers all VMs in the project.
- `source_machine_type` — `"VMware"` (default) or `"HyperV"`

**Key outputs:**
- `discovered_servers` — Filtered list with machine name, IPs, OS, boot type, and OS disk ID
- `discovered_servers_count` — Total number of discovered servers
- `discovered_servers_raw` — Full API response for debugging

**Example output:**
```
discovered_servers = [
  {
    index            = 1
    machine_name     = "web-server-01"
    ip_addresses     = "10.0.1.10, 10.0.1.11"
    operating_system = "Windows Server 2019"
    boot_type        = "EFI"
    os_disk_id       = "6000C290-a4d0-e5ea-bad5-4e993df22e3b"
  },
  ...
]
```

> **Tip:** Use the `os_disk_id` from discovery output as input for the replicate step.

---

### 3. Initialize Replication Infrastructure

Sets up all infrastructure required before replication can begin:
- **Replication Vault** — manages the replication lifecycle
- **Replication Policy** — defines recovery point history, crash/app-consistent snapshot frequencies
- **Cache Storage Account** — used for replication data staging
- **Replication Extension** — links source and target fabrics through the vault
- **Role Assignments** — grants the vault and DRA agents access to the storage account

```hcl
module "initialize" {
  source  = "Azure/avm-ptn-azure-local-migrate/azurerm"
  version = "~> 0.1"

  location       = "eastus"
  name           = "initialize"
  parent_id      = "/subscriptions/<sub-id>/resourceGroups/<rg-name>"
  operation_mode = "initialize"
  project_name   = "my-migrate-project"
  instance_type  = "VMwareToAzStackHCI"

  # Appliance names — fabrics are auto-discovered from these
  source_appliance_name = "src-appliance"
  target_appliance_name = "tgt-appliance"

  # Optional: Replication policy settings
  recovery_point_history_minutes     = 4320  # 72 hours
  crash_consistent_frequency_minutes = 60    # 1 hour
  app_consistent_frequency_minutes   = 240   # 4 hours

  # Optional: Use an existing cache storage account
  # cache_storage_account_id = "/subscriptions/.../storageAccounts/existing-account"
}
```

**Fabric auto-discovery:** The module always resolves replication fabrics from `source_appliance_name` and `target_appliance_name`. This mirrors the Az.Migrate PowerShell cmdlet `Initialize-AzMigrateLocalReplicationInfrastructure`, which never exposes fabric IDs to the caller.

**Key outputs:**
- `replication_vault_id` — Vault ARM ID (needed for replicate step)
- `replication_policy_id` — Policy ARM ID
- `replication_extension_id` — Extension ARM ID
- `replication_extension_name` — Extension name (needed for replicate step)
- `cache_storage_account_id` — Storage account ARM ID
- `source_fabric_id` / `target_fabric_id` — Resolved fabric IDs (read-only)

> **Brownfield:** If replication infrastructure already exists (vault, policy, extension), the module detects it and skips creation. See [Brownfield Support](#brownfield-support).

---

### 4. Replicate VMs

Starts replication of a source VM to Azure Stack HCI by creating a "protected item" in the replication vault.

#### Default User Mode (Single Disk/NIC)

```hcl
module "replicate" {
  source  = "Azure/avm-ptn-azure-local-migrate/azurerm"
  version = "~> 0.1"

  location       = "eastus"
  name           = "replicate-vm"
  parent_id      = "/subscriptions/<sub-id>/resourceGroups/<rg-name>"
  operation_mode = "replicate"
  project_name   = "my-migrate-project"
  instance_type  = "VMwareToAzStackHCI"

  # VM to replicate
  machine_id = "/subscriptions/.../machines/<machine-guid>"

  # Replication infrastructure (from initialize outputs)
  replication_vault_id       = module.initialize.replication_vault_id
  replication_extension_name = module.initialize.replication_extension_name
  policy_name                = basename(module.initialize.replication_policy_id)

  # OS disk (from discover output)
  os_disk_id      = "6000C290-a4d0-e5ea-bad5-4e993df22e3b"
  os_disk_size_gb = 40

  # Network (default user mode — single NIC)
  nic_id                   = "4000"
  target_virtual_switch_id = "/subscriptions/.../logicalnetworks/my-lnet"

  # Target VM configuration
  target_vm_name           = "my-vm-migrated"
  target_resource_group_id = "/subscriptions/.../resourceGroups/target-rg"
  target_storage_path_id   = "/subscriptions/.../storagecontainers/my-storage"
  target_hci_cluster_id    = "/subscriptions/.../clusters/my-cluster"
  custom_location_id       = "/subscriptions/.../customLocations/my-cl"
  hyperv_generation        = "2"

  # VM sizing
  source_vm_cpu_cores = 4
  source_vm_ram_mb    = 4096
  target_vm_cpu_cores = 4
  target_vm_ram_mb    = 4096

  # Appliance/DRA info
  source_appliance_name    = "src-appliance"
  target_appliance_name    = "tgt-appliance"
  source_fabric_agent_name = "src-dra"
  target_fabric_agent_name = "tgt-dra"
  run_as_account_id        = "/subscriptions/.../runasaccounts/<account-id>"
}
```

#### Power User Mode (Multiple Disks/NICs)

For VMs with multiple disks or NICs, use `disks_to_include` and `nics_to_include`:

```hcl
module "replicate" {
  source  = "Azure/avm-ptn-azure-local-migrate/azurerm"
  version = "~> 0.1"

  # ... (common configuration as above) ...

  disks_to_include = [
    {
      disk_id          = "6000C290-a4d0-e5ea-bad5-4e993df22e3b"
      disk_size_gb     = 40
      disk_file_format = "VHDX"
      is_os_disk       = true
      is_dynamic       = true
    },
    {
      disk_id          = "6000C29a-bcb7-a62b-7ed0-0c78f3dc1f80"
      disk_size_gb     = 100
      disk_file_format = "VHDX"
      is_os_disk       = false
      is_dynamic       = true
    }
  ]

  nics_to_include = [
    {
      nic_id            = "4000"
      target_network_id = "/subscriptions/.../logicalnetworks/prod-lnet"
      test_network_id   = "/subscriptions/.../logicalnetworks/test-lnet"
      selection_type    = "SelectedByUser"
    }
  ]
}
```

**Key outputs:**
- `protected_item_id` — ARM ID of the created protected item (needed for get/migrate/remove)
- `protected_item_name` — Name of the protected item
- `replication_state` — Current replication health

---

### 5. Monitor Replication Jobs

Queries replication job status. You can list all jobs or retrieve a specific job by name.

```hcl
# List all jobs
module "jobs" {
  source  = "Azure/avm-ptn-azure-local-migrate/azurerm"
  version = "~> 0.1"

  location             = "eastus"
  name                 = "replication-jobs"
  parent_id            = "/subscriptions/<sub-id>/resourceGroups/<rg-name>"
  operation_mode       = "jobs"
  project_name         = "my-migrate-project"
  replication_vault_id = "/subscriptions/.../replicationVaults/my-vault"
  instance_type        = "VMwareToAzStackHCI"
}
```

```hcl
# Get specific job
module "specific_job" {
  source  = "Azure/avm-ptn-azure-local-migrate/azurerm"
  version = "~> 0.1"

  # ... same as above, plus:
  job_name = "my-specific-job-name"
}
```

**Key outputs:**
- `replication_jobs` — Summary of all jobs (name, state, VM, timestamps)
- `replication_jobs_count` — Total number of jobs
- `replication_job` — Detailed info for a specific job (including tasks and errors)

---

### 6. List Protected Items

Lists all protected (replicating) items in a replication vault.

```hcl
module "list" {
  source  = "Azure/avm-ptn-azure-local-migrate/azurerm"
  version = "~> 0.1"

  location       = "eastus"
  name           = "list-items"
  parent_id      = "/subscriptions/<sub-id>/resourceGroups/<rg-name>"
  operation_mode = "list"
  project_name   = "my-migrate-project"
  instance_type  = "VMwareToAzStackHCI"
}
```

**Key outputs:**
- `protected_items_summary` — Summary with name, ID, state, health, source/target VM names
- `protected_items_count` — Total number of protected items
- `protected_items_by_state` — Items grouped by protection state
- `protected_items_by_health` — Items grouped by replication health
- `protected_items_with_errors` — Items that have health errors

---

### 7. Get Protected Item Details

Retrieves detailed status for a specific protected item. You can query by ID or by name.

```hcl
# By ID
module "get_by_id" {
  source  = "Azure/avm-ptn-azure-local-migrate/azurerm"
  version = "~> 0.1"

  location          = "eastus"
  name              = "get-item"
  parent_id         = "/subscriptions/<sub-id>/resourceGroups/<rg-name>"
  operation_mode    = "get"
  project_name      = "my-migrate-project"
  instance_type     = "VMwareToAzStackHCI"
  protected_item_id = "/subscriptions/.../protectedItems/<item-name>"
}

# By name
module "get_by_name" {
  source  = "Azure/avm-ptn-azure-local-migrate/azurerm"
  version = "~> 0.1"

  # ... same as above, but use protected_item_name instead:
  protected_item_name = "my-protected-item"
}
```

**Key outputs:**
- `protected_item_summary` — Key fields: state, health, allowed jobs, source/target names
- `protected_item_custom_properties` — Fabric-specific details, disk config, network settings
- `protected_item_health_errors` — Any health errors

---

### 8. Migrate (Planned Failover)

Performs the final migration by executing a planned failover. This creates the VM on the target Azure Stack HCI cluster.

```hcl
module "migrate" {
  source  = "Azure/avm-ptn-azure-local-migrate/azurerm"
  version = "~> 0.1"

  location           = "eastus"
  name               = "migrate-vm"
  parent_id          = "/subscriptions/<sub-id>/resourceGroups/<rg-name>"
  operation_mode     = "migrate"
  instance_type      = "VMwareToAzStackHCI"
  protected_item_id  = "/subscriptions/.../protectedItems/<item-name>"
  shutdown_source_vm = true  # Recommended for production
}
```

**Key inputs:**
- `protected_item_id` — The protected item ARM ID (from replicate or list outputs)
- `shutdown_source_vm` — `true` to shut down source VM before failover (recommended for data consistency)

**Key outputs:**
- `migration_status` — Operation status, source/target VM names
- `migration_protected_item_details` — Details of the item being migrated
- `migration_validation_warnings` — Any health warnings detected before migration

> **Important:** The protected item must be in a `Protected` state with `PlannedFailover` in its `allowedJobs` before migration can proceed. Use the `get` operation to verify readiness.

---

### 9. Remove Replication

Disables and removes replication for a protected item. Use this to clean up after a successful migration, or to cancel replication.

```hcl
module "remove" {
  source  = "Azure/avm-ptn-azure-local-migrate/azurerm"
  version = "~> 0.1"

  location         = "eastus"
  name             = "remove-replication"
  parent_id        = "/subscriptions/<sub-id>/resourceGroups/<rg-name>"
  operation_mode   = "remove"
  target_object_id = "/subscriptions/.../protectedItems/<item-name>"
  force_remove     = false  # Set true only if normal removal fails
}
```

**Key inputs:**
- `target_object_id` — The protected item ARM ID to remove
- `force_remove` — Force removal even if the item is in an inconsistent state

**Key outputs:**
- `removal_status` — Operation status and confirmation message
- `protected_item_details` — Details of the item before removal

> **Caution:** Setting `force_remove = true` may leave resources in an inconsistent state. Use it only as a last resort.

---

## End-to-End Migration

The `end-to-end` example demonstrates a complete migration workflow for multiple VMs in a single Terraform configuration. It orchestrates all steps automatically:

```
Step 0: Initialize  →  Step 1: Replicate  →  Wait for sync  →  Step 2: Verify  →  Step 3: Migrate
```

### Usage

1. Copy the `examples/end-to-end/` directory
2. Create `terraform.tfvars` from the example:
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```
3. Edit `terraform.tfvars` with your environment values
4. Define your VMs in the `vms` variable map:

```hcl
vms = {
  "web-server" = {
    machine_id        = "/subscriptions/.../machines/<guid>"
    target_vm_name    = "web-server-migrated"
    os_disk_id        = "6000C290-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
    os_disk_size_gb   = 40
    hyperv_generation = "2"
    source_vm_cpu_cores = 4
    source_vm_ram_mb    = 8192
    target_vm_cpu_cores = 4
    target_vm_ram_mb    = 8192
    disks_to_include = [
      {
        disk_id      = "6000C290-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
        disk_size_gb = 40
        is_os_disk   = true
      }
    ]
    nics_to_include = [
      {
        nic_id            = "4000"
        target_network_id = "/subscriptions/.../logicalnetworks/my-lnet"
      }
    ]
  }
}
```

5. Run the migration:
   ```bash
   terraform init
   terraform apply
   ```

The end-to-end example includes a PowerShell polling script that waits for initial replication to complete before proceeding with migration. This can take minutes to hours depending on VM disk size and network bandwidth.

---

## Configuration Modes

### Default User Mode

Suitable for VMs with a single OS disk and a single NIC. Provide individual variables:

| Variable | Description |
|---|---|
| `os_disk_id` | OS disk identifier from discovery |
| `os_disk_size_gb` | Size of the OS disk in GB |
| `nic_id` | NIC identifier |
| `target_virtual_switch_id` | Target logical network ARM ID |

### Power User Mode

For VMs with multiple disks and/or multiple NICs. Provide lists:

| Variable | Description |
|---|---|
| `disks_to_include` | List of disk objects with `disk_id`, `disk_size_gb`, `is_os_disk`, etc. |
| `nics_to_include` | List of NIC objects with `nic_id`, `target_network_id`, `test_network_id`, etc. |

Power user mode takes priority — if `disks_to_include` is non-empty, the `os_disk_id`/`os_disk_size_gb` variables are ignored. Similarly for NICs.

---

## Supported Migration Paths

| Source | Target | `instance_type` value |
|---|---|---|
| VMware vCenter | Azure Stack HCI | `VMwareToAzStackHCI` |
| Hyper-V | Azure Stack HCI | `HyperVToAzStackHCI` |

Set `instance_type` to match your source environment. This affects fabric discovery, replication extension configuration, and the failover API used.

---

## Variable Reference

### Required Variables

| Variable | Type | Description |
|---|---|---|
| `name` | `string` | Name of the migration resource (2-80 chars, alphanumeric + hyphens) |
| `location` | `string` | Azure region for resource deployment |
| `parent_id` | `string` | Resource group ARM ID (`/subscriptions/{sub}/resourceGroups/{rg}`) |

### Operation Control

| Variable | Type | Default | Description |
|---|---|---|---|
| `operation_mode` | `string` | `"discover"` | Which operation to perform |
| `instance_type` | `string` | `"VMwareToAzStackHCI"` | Source environment type |
| `create_migrate_project` | `bool` | `false` | Whether to create a new project |

### Project & Infrastructure

| Variable | Type | Default | Description |
|---|---|---|---|
| `project_name` | `string` | `null` | Azure Migrate project name |
| `appliance_name` | `string` | `null` | Appliance name for filtering discovery |
| `source_appliance_name` | `string` | `null` | Source appliance name (for fabric auto-discovery) |
| `target_appliance_name` | `string` | `null` | Target appliance name (for fabric auto-discovery) |
| `cache_storage_account_id` | `string` | `null` | Existing cache storage account ARM ID |

### Replication Policy

| Variable | Type | Default | Description |
|---|---|---|---|
| `recovery_point_history_minutes` | `number` | `4320` (72h) | How long to retain recovery points |
| `crash_consistent_frequency_minutes` | `number` | `60` (1h) | Crash-consistent snapshot interval |
| `app_consistent_frequency_minutes` | `number` | `240` (4h) | App-consistent snapshot interval |
| `policy_name` | `string` | `null` | Custom policy name (auto-generated if null) |

### VM Replication

| Variable | Type | Default | Description |
|---|---|---|---|
| `machine_id` | `string` | `null` | Source VM ARM ID from discovery |
| `machine_name` | `string` | `null` | Source machine internal name |
| `target_vm_name` | `string` | `null` | Name for the migrated VM |
| `hyperv_generation` | `string` | `"1"` | Hyper-V generation (`"1"` or `"2"`) |
| `source_vm_cpu_cores` | `number` | `2` | Source VM CPU cores |
| `source_vm_ram_mb` | `number` | `4096` | Source VM RAM in MB |
| `target_vm_cpu_cores` | `number` | `null` | Target VM CPU cores |
| `target_vm_ram_mb` | `number` | `null` | Target VM RAM in MB |
| `is_dynamic_memory_enabled` | `bool` | `false` | Enable dynamic memory on target |

### Target Configuration

| Variable | Type | Default | Description |
|---|---|---|---|
| `custom_location_id` | `string` | `null` | Azure Stack HCI custom location ARM ID |
| `target_hci_cluster_id` | `string` | `null` | Target HCI cluster ARM ID |
| `target_resource_group_id` | `string` | `null` | Target resource group ARM ID |
| `target_storage_path_id` | `string` | `null` | Target storage container ARM ID |
| `target_virtual_switch_id` | `string` | `null` | Target logical network ARM ID |

### Migration & Removal

| Variable | Type | Default | Description |
|---|---|---|---|
| `protected_item_id` | `string` | `null` | Protected item ARM ID (for get/migrate) |
| `shutdown_source_vm` | `bool` | `false` | Shut down source before migration |
| `target_object_id` | `string` | `null` | Protected item ARM ID (for remove) |
| `force_remove` | `bool` | `false` | Force removal of replication |

---

## Output Reference

### Discover Mode

| Output | Description |
|---|---|
| `discovered_servers` | Filtered list: machine name, IPs, OS, boot type, OS disk ID |
| `discovered_servers_count` | Number of discovered servers |
| `discovered_servers_raw` | Full API response |

### Initialize Mode

| Output | Description |
|---|---|
| `replication_vault_id` | Vault ARM ID |
| `replication_policy_id` | Policy ARM ID |
| `replication_extension_id` | Extension ARM ID |
| `replication_extension_name` | Extension name |
| `cache_storage_account_id` | Storage account ARM ID |
| `source_fabric_id` / `target_fabric_id` | Resolved fabric ARM IDs |
| `replication_fabrics_available` | All fabrics in the resource group |

### Replicate Mode

| Output | Description |
|---|---|
| `protected_item_id` | Protected item ARM ID |
| `protected_item_name` | Protected item name |
| `replication_state` | Current replication health |

### Jobs Mode

| Output | Description |
|---|---|
| `replication_jobs` | Summary of all jobs |
| `replication_jobs_count` | Total job count |
| `replication_job` | Details for a specific job |

### List Mode

| Output | Description |
|---|---|
| `protected_items_summary` | Summary of all protected items |
| `protected_items_count` | Total protected item count |
| `protected_items_by_state` | Items grouped by state |
| `protected_items_by_health` | Items grouped by health |

### Get Mode

| Output | Description |
|---|---|
| `protected_item_summary` | Key protected item info |
| `protected_item_custom_properties` | Disk/network/fabric details |
| `protected_item_health_errors` | Health errors |

### Migrate Mode

| Output | Description |
|---|---|
| `migration_status` | Operation status and VM names |
| `migration_protected_item_details` | Pre-migration item details |
| `migration_validation_warnings` | Pre-migration warnings |

---

## Brownfield Support

The module is designed to work safely with existing Azure Migrate infrastructure. It detects and skips creation of resources that already exist:

| Resource | Detection Method |
|---|---|
| Replication Vault | Queries the DataReplication solution for an existing `vaultId` |
| Replication Policy | Lists existing policies and matches on `instanceType` |
| Replication Extension | Lists existing extensions and matches on expected naming pattern |
| Role Assignments | Lists assignments on cache storage account and checks for matching principal+role |
| Cache Storage Account | Uses `cache_storage_account_id` if provided |

This means you can safely run `initialize` multiple times — existing resources are reused, and only missing resources are created.

---

## Troubleshooting

### Common Issues

#### "Fabric not found" during initialize

- Ensure your source and target appliances are registered and their status is **Succeeded** in the Azure portal
- Verify `source_appliance_name` / `target_appliance_name` match the fabric name prefix
- Use the `replication_fabrics_available` output to see all detected fabrics

#### Replication stuck in "InitialReplicationInProgress"

- This is normal behavior — initial replication can take minutes to hours depending on VM disk size and network bandwidth
- Use the `jobs` mode to monitor progress
- The end-to-end example includes an automated polling mechanism

#### "DisableProtection not in allowedJobs" during remove

- The VM may be in a transient state. Wait and retry.
- If stuck, use `force_remove = true`

#### "PlannedFailover not in allowedJobs" during migrate

- Replication must be complete and the item must be in `Protected` state
- Check for health errors using the `get` mode
- Ensure no resynchronization is required

#### Role assignment conflicts

- If you see "role assignment already exists" errors, the module's brownfield detection should handle this automatically
- Ensure `cache_storage_account_id` is provided when using an existing storage account

### Debugging Tips

1. Use `terraform plan` to preview what will change before applying
2. Check `discovered_servers_raw` for full API response data
3. Use `replication_fabrics_available` output to verify fabric discovery
4. Check `protected_item_health_errors` for replication health issues
5. Enable verbose logging: `TF_LOG=DEBUG terraform apply`

---

## FAQ

**Q: Can I migrate multiple VMs at once?**
A: Yes. Use `for_each` with the module (as shown in the end-to-end example) to replicate and migrate multiple VMs in parallel.

**Q: Can I use this with an existing Azure Migrate project?**
A: Yes. Set `create_migrate_project = false` (the default) and provide the existing `project_name`. The module will query the existing project.

**Q: What happens if I run `terraform apply` again after a successful migration?**
A: The module is idempotent for infrastructure setup (initialize). For replicate/migrate operations, resources are managed by Terraform state. Re-applying will not re-migrate already migrated VMs.

**Q: Can I customize the target VM sizing?**
A: Yes. Use `target_vm_cpu_cores` and `target_vm_ram_mb` to set different values from the source VM.

**Q: How do I handle VMs with multiple disks?**
A: Use the `disks_to_include` variable (power user mode). Provide a list of disk objects where exactly one has `is_os_disk = true`.

**Q: Is the source VM shut down during migration?**
A: Only if you set `shutdown_source_vm = true`. This is recommended for production migrations to ensure data consistency.

**Q: What Hyper-V generation should I use?**
A: Use `"1"` for BIOS-based VMs and `"2"` for EFI/UEFI-based VMs. This must match the source VM's boot type.

**Q: Can I rollback a migration?**
A: A planned failover is a one-way operation. Ensure you have validated the replicated data before proceeding.

---

## Support

- **Terraform Registry:** <https://registry.terraform.io/modules/Azure/avm-ptn-azure-local-migrate/azurerm/latest>
- **GitHub Repository:** <https://github.com/Azure/terraform-azurerm-avm-ptn-azure-local-migrate>
- **AVM Documentation:** <https://azure.github.io/Azure-Verified-Modules/>
- **Azure Migrate Documentation:** <https://learn.microsoft.com/azure/migrate/>
- **Issues:** File issues in the [GitHub repository](https://github.com/Azure/terraform-azurerm-avm-ptn-azure-local-migrate/issues)
