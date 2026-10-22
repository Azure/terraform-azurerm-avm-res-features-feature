terraform {
  required_version = "~> 1.5"

  required_providers {
    # tflint-ignore: terraform_unused_required_providers
    azapi = {
      source  = "Azure/azapi"
      version = "~> 2.12"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.21"
    }
  }
}

provider "azurerm" {
  features {}
}

# This is the module call for feature registration
# Feature registration operates at subscription level, not resource group level
module "test" {
  source = "../../"

  location = var.location
  # source             = "Azure/avm-res-features-feature/azurerm"
  # Register the InGuestPatchVMPreview feature for Microsoft.Compute
  # This is a preview feature that is typically not registered by default
  name             = "InGuestPatchVMPreview"
  provider_name    = "Microsoft.Compute"
  enable_telemetry = var.enable_telemetry
}
