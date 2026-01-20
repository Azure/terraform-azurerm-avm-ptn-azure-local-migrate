# Remove Replication Example

This example demonstrates how to remove/disable VM replication using the `remove` operation mode.

## Overview

The remove operation disables protection for a replicated VM and removes it from the replication vault. This is useful when:

- You want to stop replicating a VM
- The migration is complete and cleanup is needed
- You need to reconfigure replication from scratch

## Prerequisites

Before running this example, you need:

1. An existing protected item (replicated VM) in a replication vault
2. The full ARM resource ID of the protected item

## Usage

1. Copy `terraform.tfvars.example` to `terraform.tfvars`
2. Update the values with your protected item details
3. Run `terraform init` and `terraform apply`

## Force Remove

The `force_remove` option should be used with caution. It forces the removal even if the protected item is in an inconsistent state, which may leave orphaned resources.
