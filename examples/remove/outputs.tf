# --------------------------------------------------------------------------------------------
# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License. See License.txt in the project root for license information.
# --------------------------------------------------------------------------------------------

output "removal_status" {
  description = "Status of the removal operation"
  value       = module.remove_replication.removal_status
}

output "removal_operation_headers" {
  description = "Response headers with job tracking information"
  value       = module.remove_replication.removal_operation_headers
}

output "protected_item_details" {
  description = "Information about the protected item before removal"
  value       = module.remove_replication.protected_item_details
}

# Derived output for removal summary
output "removal_summary" {
  description = "Summary of the removal operation"
  value = {
    target_object_id = var.target_object_id
    force_remove     = var.force_remove
    status           = try(module.remove_replication.removal_status.operation_status, "Unknown")
    message          = try(module.remove_replication.removal_status.message, "N/A")
  }
}
