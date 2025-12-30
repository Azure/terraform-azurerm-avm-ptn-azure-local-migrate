# Azure Stack HCI Migration Module - Examples

This directory contains examples demonstrating the six main migration operations supported by this module.

## Available Examples

### 1. Discover Servers (`discover/`)
Retrieve discovered servers from Azure Migrate project (VMware or HyperV).

### 2. Initialize Replication Infrastructure (`initialize/`)
Set up replication infrastructure for Azure Stack HCI migration.

### 3. Replicate VMs (`replicate/`)
Create VM replication to Azure Stack HCI.

### 4. Get Protected Item (`get/`)
Retrieve detailed information about a protected item (replicated VM).

### 5. Monitor Jobs (`jobs/`)
Get replication job status and history.

### 6. Remove Replication (`remove/`)
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
| `operation_mode = "get"` | `get_local_server_replication()` |
| `operation_mode = "jobs"` | `get_replication_jobs()` |
| `operation_mode = "remove"` | `remove_local_server_replication()` |

## Migration Workflow

1. **Discover** → Find available VMs to migrate
2. **Initialize** → Set up replication infrastructure
3. **Replicate** → Start VM replication to Azure Stack HCI
4. **Get** → Check replication status and health
5. **Jobs** → Monitor ongoing operations
6. **Remove** → Clean up when done

See individual example directories for detailed usage.

