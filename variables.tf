variable "name" {
  type        = string
  description = "The name of the feature to register (e.g., 'EncryptionAtHost', 'AKSAzureKeyVaultSecretsProvider')."
  nullable    = false

  validation {
    condition     = length(var.name) > 0
    error_message = "The feature name must not be empty."
  }
}

variable "provider_name" {
  type        = string
  description = "The namespace of the Resource Provider which should be registered."
  nullable    = false

  validation {
    condition     = can(regex("^Microsoft\\.[A-Za-z0-9]+$", var.provider_name))
    error_message = "The provider name must be in the format 'Microsoft.<provider>' (e.g., 'Microsoft.Compute')."
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

variable "feature_registration_timeouts" {
  type = object({
    create = optional(string, "120m")
    delete = optional(string, "30m")
    read   = optional(string, "5m")
  })
  default = {
    create = "120m"
    delete = "30m"
    read   = "5m"
  }
  description = <<DESCRIPTION
Timeout configuration for the feature registration operation.

- `create` - (Optional) Timeout for registering the feature. Defaults to 120 minutes.
- `delete` - (Optional) Timeout for unregistering the feature during destroy. Defaults to 30 minutes.
- `read` - (Optional) Timeout for reading the feature status. Defaults to 5 minutes.
DESCRIPTION
  nullable    = false
}

variable "feature_unregistration_timeouts" {
  type = object({
    create = optional(string, "30m")
    delete = optional(string, "30m")
    read   = optional(string, "5m")
  })
  default = {
    create = "30m"
    delete = "30m"
    read   = "5m"
  }
  description = <<DESCRIPTION
Timeout configuration for the feature unregistration operation that runs on destroy.

- `create` - (Optional) Timeout for the unregistration operation. Defaults to 30 minutes.
- `delete` - (Optional) Timeout for cleanup. Defaults to 30 minutes.
- `read` - (Optional) Timeout for reading the status. Defaults to 5 minutes.
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
