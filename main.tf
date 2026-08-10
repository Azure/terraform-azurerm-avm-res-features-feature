# Azure Feature Registration using AzAPI
data "azapi_client_config" "current" {}

# Register the feature (on apply) and unregister (on destroy)
resource "azapi_resource_action" "feature_registration" {
  action                 = "register"
  method                 = "POST"
  resource_id            = local.feature_resource_id
  type                   = "${var.provider_name}/features@2021-07-01"
  response_export_values = ["*"]

  timeouts {
    create = var.feature_registration_timeouts.create
    delete = var.feature_registration_timeouts.delete
    read   = var.feature_registration_timeouts.read
  }
}

# Unregister the feature when the resource is destroyed
resource "azapi_resource_action" "feature_unregistration" {
  action      = "unregister"
  method      = "POST"
  resource_id = local.feature_resource_id
  type        = "${var.provider_name}/features@2021-07-01"
  when        = "destroy"

  timeouts {
    create = var.feature_unregistration_timeouts.create
    delete = var.feature_unregistration_timeouts.delete
    read   = var.feature_unregistration_timeouts.read
  }

  depends_on = [azapi_resource_action.feature_registration]
}

# Get the feature registration status to track state
data "azapi_resource" "feature_status" {
  resource_id = local.feature_resource_id
  type        = "${var.provider_name}/features@2021-07-01"

  depends_on = [azapi_resource_action.feature_registration]
}

resource "azapi_resource" "lock" {
  count = var.lock != null ? 1 : 0

  name           = coalesce(module.avm_utl_interfaces.lock_azapi.name, "lock-${var.provider_name}")
  parent_id      = data.azapi_resource.feature_status.id
  type           = module.avm_utl_interfaces.lock_azapi.type
  body           = module.avm_utl_interfaces.lock_azapi.body
  create_headers = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  delete_headers = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  read_headers   = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  update_headers = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null

  depends_on = [azapi_resource.role_assignments]
}

resource "azapi_resource" "role_assignments" {
  for_each = var.role_assignments

  name      = module.avm_utl_interfaces.role_assignments_azapi[each.key].name
  parent_id = data.azapi_resource.feature_status.id
  type      = module.avm_utl_interfaces.role_assignments_azapi[each.key].type
  body = {
    properties = {
      principalId                        = module.avm_utl_interfaces.role_assignments_azapi[each.key].body.properties.principalId
      roleDefinitionId                   = module.avm_utl_interfaces.role_assignments_azapi[each.key].body.properties.roleDefinitionId
      condition                          = module.avm_utl_interfaces.role_assignments_azapi[each.key].body.properties.condition
      conditionVersion                   = module.avm_utl_interfaces.role_assignments_azapi[each.key].body.properties.conditionVersion
      delegatedManagedIdentityResourceId = module.avm_utl_interfaces.role_assignments_azapi[each.key].body.properties.delegatedManagedIdentityResourceId
      description                        = module.avm_utl_interfaces.role_assignments_azapi[each.key].body.properties.description == null ? "" : module.avm_utl_interfaces.role_assignments_azapi[each.key].body.properties.description
      principalType                      = module.avm_utl_interfaces.role_assignments_azapi[each.key].body.properties.principalType
    }
  }
  create_headers = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  delete_headers = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  read_headers   = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  # retry = {
  #   error_message_regex = [
  #     ".*Please remove the lock and try again.*",
  #   ]
  # }
  update_headers = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null

  lifecycle {
    ignore_changes = [
      body.properties.principalType,
    ]
  }
  depends_on = [
    azapi_resource_action.feature_registration,
  ]
}

# Terraform data resource to track role assignment changes that require updates via azapi_update_resource
# This triggers replacement when tracked values change, which then triggers the azapi_update_resource
resource "terraform_data" "role_assignments_update_tracker" {
  for_each = var.role_assignments

  input = {
    principal_type = module.avm_utl_interfaces.role_assignments_azapi[each.key].body.properties.principalType
  }
}

# Update role assignment properties using azapi_update_resource to maintain idempotency
# This is necessary because principalType is ignored in the main resource to prevent drift
# while still allowing updates to be applied when explicitly changed
resource "azapi_update_resource" "role_assignments" {
  for_each = var.role_assignments

  resource_id = azapi_resource.role_assignments[each.key].id
  type        = module.avm_utl_interfaces.role_assignments_azapi[each.key].type
  body = {
    properties = {
      principalType = module.avm_utl_interfaces.role_assignments_azapi[each.key].body.properties.principalType
    }
  }
  read_headers   = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  update_headers = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null

  # Trigger update when update_tracker is replaced
  lifecycle {
    ignore_changes = [
      body,
    ]
    replace_triggered_by = [
      terraform_data.role_assignments_update_tracker[each.key]
    ]
  }
}
