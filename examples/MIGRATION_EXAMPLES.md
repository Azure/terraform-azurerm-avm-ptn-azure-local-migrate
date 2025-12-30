# Azure Stack HCI Migration Module - Examples

This directory contains examples demonstrating the seven main migration operations supported by this module.

## Available Examples

### 1. Discover Servers (`discover/`)
Retrieve discovered servers from Azure Migrate project (VMware or HyperV).

### 2. Initialize Replication Infrastructure (`initialize/`)
Set up replication infrastructure for Azure Stack HCI migration.

### 3. Replicate VMs (`replicate/`)
Create VM replication to Azure Stack HCI.

### 4. List Protected Items (`list/`)
List all protected items (replicated VMs) in the vault.

### 5. Get Protected Item (`get/`)
Retrieve detailed information about a specific protected item (replicated VM).

### 6. Monitor Jobs (`jobs/`)
Get replication job status and history.

### 7. Remove Replication (`remove/`)
Disable replication for a protected item.

## Quick Start

Each example is self-contained and can be run independently:

```bash
cd <example-directory>
terraform init
terraform plan
terraform apply
```

## Python CLI Equivalent

This Terraform module provides equivalent functionality to these Azure CLI Python commands:

| Terraform Operation | Python CLI Command |
|--------------------|--------------------|
| `operation_mode = "discover"` | `get_discovered_server()` |
| `operation_mode = "initialize"` | `initialize_replication_infrastructure()` |
| `operation_mode = "replicate"` | `new_local_server_replication()` |
| `operation_mode = "list"` | `list_local_server_replications()` |
| `operation_mode = "get"` | `get_local_server_replication()` |
| `operation_mode = "jobs"` | `get_replication_jobs()` |
| `operation_mode = "remove"` | `remove_local_server_replication()` |

## Migration Workflow

1. **Discover** → Find available VMs to migrate
2. **Initialize** → Set up replication infrastructure
3. **Replicate** → Start VM replication to Azure Stack HCI
4. **List** → View all replicating VMs and their status
5. **Get** → Check detailed status of a specific VM
6. **Jobs** → Monitor ongoing operations
7. **Remove** → Clean up when done

See individual example directories for detailed usage.

