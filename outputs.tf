output "resource_id" {
  description = "The ID of the feature registration."
  value       = data.azapi_resource.feature_status.id
}
