# Azure Stack HCI Migration Module - Examples

This directory contains examples demonstrating the three main migration commands supported by this module.

## Available Examples

### 1. Discover Servers (`discover/`)
Retrieve discovered servers from Azure Migrate project (VMware or HyperV).

### 2. Initialize Replication Infrastructure (`initialize/`)
Set up replication infrastructure for Azure Stack HCI migration.

### 3. Replicate VMs (`replicate/`)
Create VM replication to Azure Stack HCI.

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

## Migration Workflow

1. **Discover** → Find available VMs to migrate
2. **Initialize** → Set up replication infrastructure
3. **Replicate** → Start VM replication to Azure Stack HCI

See individual example directories for detailed usage.
