module "avm_utl_interfaces" {
  source  = "Azure/avm-utl-interfaces/azure"
  version = "0.4.0"

  enable_telemetry = var.enable_telemetry
  lock = var.lock == null ? null : {
    kind = var.lock.kind
    name = var.lock.name
  }
  role_assignment_definition_scope = data.azapi_resource.feature_status.id
  role_assignments = { for k, v in var.role_assignments : k => {
    role_definition_id_or_name             = v.role_definition_id_or_name
    principal_id                           = v.principal_id
    description                            = v.description
    skip_service_principal_aad_check       = v.skip_service_principal_aad_check
    condition                              = v.condition
    condition_version                      = v.condition_version
    delegated_managed_identity_resource_id = v.delegated_managed_identity_resource_id
    principal_type                         = v.principal_type
  } }
}
