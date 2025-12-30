output "cache_storage_account_id" {
  description = "ID of the cache storage account"
  value       = module.initialize_replication.cache_storage_account_id
}

output "replication_extension_name" {
  description = "Name of the replication extension (needed for VM replication)"
  value       = module.initialize_replication.replication_extension_name
}

output "replication_policy_id" {
  description = "ID of the replication policy"
  value       = module.initialize_replication.replication_policy_id
}

# Outputs
output "replication_vault_id" {
  description = "ID of the replication vault"
  value       = module.initialize_replication.replication_vault_id
}

output "vault_identity" {
  description = "Managed identity principal ID of the vault"
  sensitive   = true
  value       = module.initialize_replication.replication_vault_identity
}
