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

<!-- BEGIN_TF_DOCS -->
<!-- END_TF_DOCS -->

<!-- markdownlint-disable-next-line MD041 -->
## Data Collection

The software may collect information about you and your use of the software and send it to Microsoft. Microsoft may use this information to provide services and improve our products and services. You may turn off the telemetry as described in the repository. There are also some features in the software that may enable you and Microsoft to collect data from users of your applications. If you use these features, you must comply with applicable law, including providing appropriate notices to users of your applications together with a copy of Microsoft's privacy statement. Our privacy statement is located at <https://go.microsoft.com/fwlink/?LinkID=824704>. You can learn more about data collection and use in the help documentation and our privacy statement. Your use of the software operates as your consent to these practices.
