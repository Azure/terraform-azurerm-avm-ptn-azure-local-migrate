# Outputs
output "protected_item_id" {
  description = "ID of the protected item (replicated VM)"
  value       = module.replicate_vm.protected_item_id
}

output "replication_state" {
  description = "Current replication state"
  value       = module.replicate_vm.replication_state
}

output "target_vm_name" {
  description = "Name of the target VM"
  value       = module.replicate_vm.target_vm_name_output
}
