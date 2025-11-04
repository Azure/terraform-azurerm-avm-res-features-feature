locals {
  feature_resource_id = "/subscriptions/${data.azapi_client_config.current.subscription_id}/providers/Microsoft.Features/providers/${var.provider_name}/features/${var.name}"
}
