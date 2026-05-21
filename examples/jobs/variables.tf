variable "parent_id" {
  type        = string
  description = "The resource ID of the resource group containing the Azure Migrate project. Format: /subscriptions/{subscription-id}/resourceGroups/{resource-group-name}"
}

variable "project_name" {
  type        = string
  default     = "<migrate-project-name>"
  description = "The name of the Azure Migrate project"
}

variable "replication_vault_id" {
  type        = string
  default     = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/<rg>/providers/Microsoft.DataReplication/replicationVaults/<vault>"
  description = "The full resource ID of the replication vault (optional, derived from project if not provided)"
}

variable "tags" {
  type = map(string)
  default = {
    Environment = "Test"
    Purpose     = "ReplicationJobs"
  }
  description = "Tags to apply to resources"
}
