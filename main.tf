# Azure Feature Registration using AzAPI
data "azapi_client_config" "current" {}

# Register the feature (on apply) and unregister (on destroy)
resource "azapi_resource_action" "feature_registration" {
  type                   = "${var.provider_name}/features@2021-07-01"
  resource_id            = "/subscriptions/${data.azapi_client_config.current.subscription_id}/providers/Microsoft.Features/providers/${var.provider_name}/features/${var.name}"
  action                 = "register"
  method                 = "POST"
  response_export_values = ["*"]

  timeouts {
    create = "120m"
    read   = "5m"
    delete = "30m"
  }
}

# Unregister the feature when the resource is destroyed
resource "azapi_resource_action" "feature_unregistration" {
  type        = "${var.provider_name}/features@2021-07-01"
  resource_id = "/subscriptions/${data.azapi_client_config.current.subscription_id}/providers/Microsoft.Features/providers/${var.provider_name}/features/${var.name}"
  action      = "unregister"
  method      = "POST"
  when        = "destroy"

  depends_on = [azapi_resource_action.feature_registration]

  timeouts {
    create = "30m"
    read   = "5m"
    delete = "30m"
  }
}

# Get the feature registration status to track state
data "azapi_resource" "feature_status" {
  type        = "${var.provider_name}/features@2021-07-01"
  resource_id = "/subscriptions/${data.azapi_client_config.current.subscription_id}/providers/Microsoft.Features/providers/${var.provider_name}/features/${var.name}"

  depends_on = [azapi_resource_action.feature_registration]
}

# required AVM resources interfaces
resource "azurerm_management_lock" "this" {
  count = var.lock != null ? 1 : 0

  lock_level = var.lock.kind
  name       = coalesce(var.lock.name, "lock-${var.lock.kind}")
  scope      = data.azapi_resource.feature_status.id
  notes      = var.lock.kind == "CanNotDelete" ? "Cannot delete the resource or its child resources." : "Cannot delete or modify the resource or its child resources."
}

resource "azurerm_role_assignment" "this" {
  for_each = var.role_assignments

  principal_id                           = each.value.principal_id
  scope                                  = data.azapi_resource.feature_status.id
  condition                              = each.value.condition
  condition_version                      = each.value.condition_version
  delegated_managed_identity_resource_id = each.value.delegated_managed_identity_resource_id
  principal_type                         = each.value.principal_type
  role_definition_id                     = strcontains(lower(each.value.role_definition_id_or_name), lower(local.role_definition_resource_substring)) ? each.value.role_definition_id_or_name : null
  role_definition_name                   = strcontains(lower(each.value.role_definition_id_or_name), lower(local.role_definition_resource_substring)) ? null : each.value.role_definition_id_or_name
  skip_service_principal_aad_check       = each.value.skip_service_principal_aad_check
}
