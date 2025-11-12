# Get Replication Jobs Example

This example demonstrates how to retrieve replication job information from Azure Migrate.

## Overview

The jobs command allows you to:
- List all replication jobs in a vault
- Get detailed information about a specific job
- Monitor job status, progress, and errors

This is equivalent to the Python CLI command:
```bash
az migrate local replication job get \
  --resource-group <resource-group> \
  --project-name <project-name>
```

## Features

- **List All Jobs**: Retrieve summary information for all jobs in the replication vault
- **Get Specific Job**: Get detailed information including tasks, errors, and timing for a specific job
- **Job Status**: View current state (Queued, InProgress, Succeeded, Failed, etc.)
- **Error Details**: See error messages, codes, and recommendations when jobs fail
- **Task Progress**: View individual task states within a job

## Usage

### List All Jobs

```terraform
module "list_jobs" {
  source = "Azure/avm-res-migrate/azurerm"

  name                = "migration-jobs"
  location            = "eastus"
  resource_group_name = "your-rg"

  operation_mode = "jobs"
  project_name   = "your-migrate-project"
}

output "all_jobs" {
  value = module.list_jobs.replication_jobs
}
```

### Get Specific Job

```terraform
module "get_job" {
  source = "Azure/avm-res-migrate/azurerm"

  name                = "migration-job-detail"
  location            = "eastus"
  resource_group_name = "your-rg"

  operation_mode       = "jobs"
  job_name             = "job-12345"
  replication_vault_id = "/subscriptions/.../replicationVaults/vault-name"
}

output "job_details" {
  value = module.get_job.replication_job
}
```

## Output Examples

### Job List Output

```json
[
  {
    "job_name": "job-12345",
    "display_name": "Enable replication for VM1",
    "state": "Succeeded",
    "vm_name": "VM1",
    "start_time": "2025-11-12T10:00:00Z",
    "end_time": "2025-11-12T10:15:00Z",
    "has_errors": false
  },
  {
    "job_name": "job-12346",
    "display_name": "Enable replication for VM2",
    "state": "InProgress",
    "vm_name": "VM2",
    "start_time": "2025-11-12T10:30:00Z",
    "end_time": null,
    "has_errors": false
  }
]
```

### Specific Job Output

```json
{
  "job_name": "job-12345",
  "display_name": "Enable replication for VM1",
  "state": "Succeeded",
  "vm_name": "VM1",
  "start_time": "2025-11-12T10:00:00Z",
  "end_time": "2025-11-12T10:15:00Z",
  "errors": [],
  "tasks": [
    {
      "name": "PreReplicationTask",
      "state": "Succeeded",
      "start_time": "2025-11-12T10:00:00Z",
      "end_time": "2025-11-12T10:05:00Z"
    },
    {
      "name": "ReplicationTask",
      "state": "Succeeded",
      "start_time": "2025-11-12T10:05:00Z",
      "end_time": "2025-11-12T10:15:00Z"
    }
  ]
}
```

## Job States

Jobs can be in one of the following states:
- **Queued**: Job is waiting to start
- **InProgress**: Job is currently running
- **Succeeded**: Job completed successfully
- **Failed**: Job failed with errors
- **Canceled**: Job was canceled
- **Suspended**: Job is temporarily suspended

## Requirements

- Azure Migrate project must exist
- Replication infrastructure must be initialized
- At least one replication job must have been created

## Common Use Cases

1. **Monitor Replication Progress**: Check the status of VM replication enablement
2. **Troubleshoot Failures**: View error details and recommendations
3. **Track Job History**: See all past jobs and their outcomes
4. **Verify Completion**: Confirm that replication setup jobs have completed successfully

## Related Commands

- **discover**: Find VMs available for migration
- **initialize**: Set up replication infrastructure
- **replicate**: Enable replication for a VM (creates jobs)
