# --------------------------------------------------------------------------------------------
# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License. See License.txt in the project root for license information.
# --------------------------------------------------------------------------------------------

output "protected_item_info" {
  description = "Information about the protected item before removal"
  value       = module.remove_replication.protected_item_info
}

output "removal_operation_headers" {
  description = "Response headers from the removal operation (includes Azure-AsyncOperation and Location for job tracking)"
  value       = module.remove_replication.removal_operation_headers
}

output "removal_status" {
  description = "Status of the replication removal operation"
  value       = module.remove_replication.removal_status
}
