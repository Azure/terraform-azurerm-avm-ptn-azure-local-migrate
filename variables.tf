variable "location" {
  type        = string
  description = "Azure region where the resource should be deployed."
  nullable    = false
}

variable "name" {
  type        = string
  description = "The name of the migration resource."

  validation {
    condition     = can(regex("^[a-zA-Z0-9][a-zA-Z0-9-]{0,78}[a-zA-Z0-9]$", var.name))
    error_message = "The name must be 2-80 characters, start and end with alphanumeric, contain only alphanumeric and hyphens."
  }
}

# This is required for most resource modules
variable "resource_group_name" {
  type        = string
  description = "The resource group where the resources will be deployed."
}

# required AVM interfaces
# remove only if not supported by the resource
# tflint-ignore: terraform_unused_declarations
variable "customer_managed_key" {
  type = object({
    key_vault_resource_id = string
    key_name              = string
    key_version           = optional(string, null)
    user_assigned_identity = optional(object({
      resource_id = string
    }), null)
  })
  default     = null
  description = <<DESCRIPTION
A map describing customer-managed keys to associate with the resource. This includes the following properties:
- `key_vault_resource_id` - The resource ID of the Key Vault where the key is stored.
- `key_name` - The name of the key.
- `key_version` - (Optional) The version of the key. If not specified, the latest version is used.
- `user_assigned_identity` - (Optional) An object representing a user-assigned identity with the following properties:
  - `resource_id` - The resource ID of the user-assigned identity.
DESCRIPTION
}

variable "diagnostic_settings" {
  type = map(object({
    name                                     = optional(string, null)
    log_categories                           = optional(set(string), [])
    log_groups                               = optional(set(string), ["allLogs"])
    metric_categories                        = optional(set(string), ["AllMetrics"])
    log_analytics_destination_type           = optional(string, "Dedicated")
    workspace_resource_id                    = optional(string, null)
    storage_account_resource_id              = optional(string, null)
    event_hub_authorization_rule_resource_id = optional(string, null)
    event_hub_name                           = optional(string, null)
    marketplace_partner_resource_id          = optional(string, null)
  }))
  default     = {}
  description = <<DESCRIPTION
A map of diagnostic settings to create on the Key Vault. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time.

- `name` - (Optional) The name of the diagnostic setting. One will be generated if not set, however this will not be unique if you want to create multiple diagnostic setting resources.
- `log_categories` - (Optional) A set of log categories to send to the log analytics workspace. Defaults to `[]`.
- `log_groups` - (Optional) A set of log groups to send to the log analytics workspace. Defaults to `["allLogs"]`.
- `metric_categories` - (Optional) A set of metric categories to send to the log analytics workspace. Defaults to `["AllMetrics"]`.
- `log_analytics_destination_type` - (Optional) The destination type for the diagnostic setting. Possible values are `Dedicated` and `AzureDiagnostics`. Defaults to `Dedicated`.
- `workspace_resource_id` - (Optional) The resource ID of the log analytics workspace to send logs and metrics to.
- `storage_account_resource_id` - (Optional) The resource ID of the storage account to send logs and metrics to.
- `event_hub_authorization_rule_resource_id` - (Optional) The resource ID of the event hub authorization rule to send logs and metrics to.
- `event_hub_name` - (Optional) The name of the event hub. If none is specified, the default event hub will be selected.
- `marketplace_partner_resource_id` - (Optional) The full ARM resource ID of the Marketplace resource to which you would like to send Diagnostic LogsLogs.
DESCRIPTION
  nullable    = false

  validation {
    condition     = alltrue([for _, v in var.diagnostic_settings : contains(["Dedicated", "AzureDiagnostics"], v.log_analytics_destination_type)])
    error_message = "Log analytics destination type must be one of: 'Dedicated', 'AzureDiagnostics'."
  }
  validation {
    condition = alltrue(
      [
        for _, v in var.diagnostic_settings :
        v.workspace_resource_id != null || v.storage_account_resource_id != null || v.event_hub_authorization_rule_resource_id != null || v.marketplace_partner_resource_id != null
      ]
    )
    error_message = "At least one of `workspace_resource_id`, `storage_account_resource_id`, `marketplace_partner_resource_id`, or `event_hub_authorization_rule_resource_id`, must be set."
  }
}

variable "enable_telemetry" {
  type        = bool
  default     = true
  description = <<DESCRIPTION
This variable controls whether or not telemetry is enabled for the module.
For more information see <https://aka.ms/avm/telemetryinfo>.
If it is set to false, then no telemetry will be collected.
DESCRIPTION
  nullable    = false
}

variable "lock" {
  type = object({
    kind = string
    name = optional(string, null)
  })
  default     = null
  description = <<DESCRIPTION
Controls the Resource Lock configuration for this resource. The following properties can be specified:

- `kind` - (Required) The type of lock. Possible values are `\"CanNotDelete\"` and `\"ReadOnly\"`.
- `name` - (Optional) The name of the lock. If not specified, a name will be generated based on the `kind` value. Changing this forces the creation of a new resource.
DESCRIPTION

  validation {
    condition     = var.lock != null ? contains(["CanNotDelete", "ReadOnly"], var.lock.kind) : true
    error_message = "The lock level must be one of: 'None', 'CanNotDelete', or 'ReadOnly'."
  }
}

# tflint-ignore: terraform_unused_declarations
variable "managed_identities" {
  type = object({
    system_assigned            = optional(bool, false)
    user_assigned_resource_ids = optional(set(string), [])
  })
  default     = {}
  description = <<DESCRIPTION
Controls the Managed Identity configuration on this resource. The following properties can be specified:

- `system_assigned` - (Optional) Specifies if the System Assigned Managed Identity should be enabled.
- `user_assigned_resource_ids` - (Optional) Specifies a list of User Assigned Managed Identity resource IDs to be assigned to this resource.
DESCRIPTION
  nullable    = false
}

variable "role_assignments" {
  type = map(object({
    role_definition_id_or_name             = string
    principal_id                           = string
    description                            = optional(string, null)
    skip_service_principal_aad_check       = optional(bool, false)
    condition                              = optional(string, null)
    condition_version                      = optional(string, null)
    delegated_managed_identity_resource_id = optional(string, null)
    principal_type                         = optional(string, null)
  }))
  default     = {}
  description = <<DESCRIPTION
A map of role assignments to create on this resource. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time.

- `role_definition_id_or_name` - The ID or name of the role definition to assign to the principal.
- `principal_id` - The ID of the principal to assign the role to.
- `description` - The description of the role assignment.
- `skip_service_principal_aad_check` - If set to true, skips the Azure Active Directory check for the service principal in the tenant. Defaults to false.
- `condition` - The condition which will be used to scope the role assignment.
- `condition_version` - The version of the condition syntax. Valid values are '2.0'.
- `delegated_managed_identity_resource_id` - The delegated Azure Resource Id which contains a Managed Identity. Changing this forces a new resource to be created.
- `principal_type` - The type of the principal_id. Possible values are `User`, `Group` and `ServicePrincipal`. Changing this forces a new resource to be created. It is necessary to explicitly set this attribute when creating role assignments if the principal creating the assignment is constrained by ABAC rules that filters on the PrincipalType attribute.

> Note: only set `skip_service_principal_aad_check` to true if you are assigning a role to a service principal.
DESCRIPTION
  nullable    = false
}

# tflint-ignore: terraform_unused_declarations
variable "tags" {
  type        = map(string)
  default     = null
  description = "(Optional) Tags of the resource."
}

# ========================================
# MIGRATION-SPECIFIC VARIABLES
# ========================================

# Operation Mode
variable "operation_mode" {
  type        = string
  description = "The migration operation to perform: discover, initialize, replicate, jobs, or remove"
  default     = "discover"

  validation {
    condition     = contains(["discover", "initialize", "replicate", "jobs", "remove"], var.operation_mode)
    error_message = "operation_mode must be one of: discover, initialize, replicate, jobs, remove."
  }
}

# COMMAND 1: DISCOVER SERVERS Variables
variable "project_name" {
  type        = string
  description = "Azure Migrate project name"
  default     = null
}

variable "source_machine_type" {
  type        = string
  description = "Source machine type (VMware or HyperV)"
  default     = "VMware"

  validation {
    condition     = contains(["VMware", "HyperV"], var.source_machine_type)
    error_message = "source_machine_type must be either VMware or HyperV."
  }
}

variable "appliance_name" {
  type        = string
  description = "Appliance name (maps to site name)"
  default     = null
}

variable "display_name" {
  type        = string
  description = "Source machine display name for filtering"
  default     = null
}

variable "machine_name" {
  type        = string
  description = "Source machine internal name"
  default     = null
}

# COMMAND 2: INITIALIZE INFRASTRUCTURE Variables
variable "source_appliance_name" {
  type        = string
  description = "Source appliance name for AzLocal scenario"
  default     = null
}

variable "target_appliance_name" {
  type        = string
  description = "Target appliance name for AzLocal scenario"
  default     = null
}

variable "cache_storage_account_id" {
  type        = string
  description = "Storage Account ARM ID for cache/private endpoint scenario"
  default     = null
}

variable "instance_type" {
  type        = string
  description = "Migration instance type"
  default     = "VMwareToAzStackHCI"

  validation {
    condition     = contains(["HyperVToAzStackHCI", "VMwareToAzStackHCI"], var.instance_type)
    error_message = "instance_type must be either HyperVToAzStackHCI or VMwareToAzStackHCI."
  }
}

variable "policy_name" {
  type        = string
  description = "Replication policy name"
  default     = null
}

variable "recovery_point_history_minutes" {
  type        = number
  description = "Recovery point retention in minutes"
  default     = 4320 # 72 hours
}

variable "crash_consistent_frequency_minutes" {
  type        = number
  description = "Crash consistent snapshot frequency in minutes"
  default     = 60 # 1 hour
}

variable "app_consistent_frequency_minutes" {
  type        = number
  description = "Application consistent snapshot frequency in minutes"
  default     = 240 # 4 hours
}

variable "source_fabric_id" {
  type        = string
  description = "Source replication fabric ARM ID"
  default     = null
}

variable "target_fabric_id" {
  type        = string
  description = "Target replication fabric ARM ID"
  default     = null
}

# COMMAND 3: CREATE REPLICATION Variables
variable "machine_id" {
  type        = string
  description = "Machine ARM ID of the discovered server to migrate"
  default     = null
}

variable "machine_index" {
  type        = number
  description = "Index of the discovered server from the list (1-based)"
  default     = null

  validation {
    condition     = var.machine_index == null || var.machine_index >= 1
    error_message = "machine_index must be a positive integer (1 or greater)."
  }
}

variable "target_vm_name" {
  type        = string
  description = "Name of the VM to be created on target"
  default     = null

  validation {
    condition     = var.target_vm_name == null || (length(var.target_vm_name) >= 1 && length(var.target_vm_name) <= 64 && can(regex("^[^_\\W][a-zA-Z0-9\\-]{0,63}$", var.target_vm_name)))
    error_message = "target_vm_name must be 1-64 characters, start with letter/number, contain only letters/numbers/hyphens."
  }
}

variable "target_storage_path_id" {
  type        = string
  description = "Storage path ARM ID where VMs will be stored"
  default     = null
}

variable "target_resource_group_id" {
  type        = string
  description = "Target resource group ARM ID for migrated VM resources"
  default     = null
}

variable "target_virtual_switch_id" {
  type        = string
  description = "Logical network ARM ID for VMs (default user mode)"
  default     = null
}

variable "target_test_virtual_switch_id" {
  type        = string
  description = "Test logical network ARM ID for VMs"
  default     = null
}

variable "target_vm_cpu_cores" {
  type        = number
  description = "Number of CPU cores for target VM"
  default     = null

  validation {
    condition     = var.target_vm_cpu_cores == null || (var.target_vm_cpu_cores >= 1 && var.target_vm_cpu_cores <= 240)
    error_message = "target_vm_cpu_cores must be between 1 and 240."
  }
}

variable "source_vm_cpu_cores" {
  type        = number
  description = "Number of CPU cores from source VM"
  default     = 2
}

variable "target_vm_ram_mb" {
  type        = number
  description = "Target RAM size in MB"
  default     = null
}

variable "source_vm_ram_mb" {
  type        = number
  description = "Source RAM size in MB"
  default     = 4096
}

variable "is_dynamic_memory_enabled" {
  type        = bool
  description = "Whether RAM is dynamic"
  default     = false
}

variable "hyperv_generation" {
  type        = string
  description = "Hyper-V generation (1 or 2)"
  default     = "1"

  validation {
    condition     = contains(["1", "2"], var.hyperv_generation)
    error_message = "hyperv_generation must be either 1 or 2."
  }
}

variable "os_disk_id" {
  type        = string
  description = "Operating system disk ID for the source server (default user mode)"
  default     = null
}

variable "disks_to_include" {
  type = list(object({
    disk_id          = string
    disk_size_gb     = number
    disk_file_format = optional(string, "VHDX")
    is_os_disk       = bool
    is_dynamic       = optional(bool, true)
  }))
  description = "Disks to include for replication (power user mode)"
  default     = []
}

variable "nics_to_include" {
  type = list(object({
    nic_id            = string
    target_network_id = string
    test_network_id   = optional(string)
    selection_type    = optional(string, "SelectedByUser")
  }))
  description = "NICs to include for replication (power user mode)"
  default     = []
}

variable "replication_vault_id" {
  type        = string
  description = "Replication vault ARM ID (for replicate mode)"
  default     = null
}

variable "replication_extension_name" {
  type        = string
  description = "Replication extension name (for replicate mode)"
  default     = null
}

variable "custom_location_id" {
  type        = string
  description = "Custom location ARM ID for Arc"
  default     = null
}

variable "source_fabric_agent_name" {
  type        = string
  description = "Source fabric agent (DRA) name"
  default     = null
}

variable "target_fabric_agent_name" {
  type        = string
  description = "Target fabric agent (DRA) name"
  default     = null
}

variable "run_as_account_id" {
  type        = string
  description = "Run-as account ARM ID"
  default     = null
}

variable "target_hci_cluster_id" {
  type        = string
  description = "Target HCI cluster ARM ID"
  default     = null
}

# COMMAND 4: GET REPLICATION JOBS Variables
variable "job_name" {
  type        = string
  description = "Specific job name to retrieve. If not provided, all jobs will be listed."
  default     = null
}

# COMMAND 5: REMOVE REPLICATION Variables
variable "target_object_id" {
  type        = string
  description = "The protected item ARM ID for which replication needs to be disabled. Required for 'remove' operation mode. Format: /subscriptions/{subscription-id}/resourceGroups/{resource-group}/providers/Microsoft.DataReplication/replicationVaults/{vault-name}/protectedItems/{item-name}"
  default     = null

  validation {
    condition = (
      var.target_object_id == null ||
      can(regex("^/subscriptions/[^/]+/resourceGroups/[^/]+/providers/Microsoft\\.DataReplication/replicationVaults/[^/]+/protectedItems/[^/]+$", var.target_object_id))
    )
    error_message = "target_object_id must be a valid protected item ARM ID in the format: /subscriptions/{subscription-id}/resourceGroups/{resource-group}/providers/Microsoft.DataReplication/replicationVaults/{vault-name}/protectedItems/{item-name}"
  }
}

variable "force_remove" {
  type        = bool
  description = "Specifies whether the replication needs to be force removed. Use with caution as force removal may leave resources in an inconsistent state."
  default     = false
}
