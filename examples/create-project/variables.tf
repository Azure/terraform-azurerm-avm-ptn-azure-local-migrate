variable "parent_id" {
  type        = string
  description = "The resource ID of the resource group where the Migrate project will be created. Format: /subscriptions/{subscription-id}/resourceGroups/{resource-group-name}"
}

variable "instance_type" {
  type        = string
  default     = "VMwareToAzStackHCI"
  description = "The migration instance type (VMwareToAzStackHCI or HyperVToAzStackHCI)"
}

variable "location" {
  type        = string
  default     = "westus2"
  description = "The Azure region where the Migrate project will be created. Note: Not all regions support Azure Migrate projects. Supported regions include: centralus, westus2, northeurope, westeurope, etc."
}

variable "project_name" {
  type        = string
  default     = "saif-project-012726"
  description = "The name of the new Azure Migrate project to create"
}

variable "tags" {
  type = map(string)
  default = {
    Environment = "Production"
    Purpose     = "MigrateProject"
    ManagedBy   = "Terraform"
  }
  description = "Tags to apply to the Azure Migrate project"
}
