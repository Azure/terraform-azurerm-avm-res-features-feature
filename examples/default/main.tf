terraform {
  required_version = "~> 1.5"

  required_providers {
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

  # source             = "Azure/avm-res-features-feature/azurerm"
  # Register the InGuestPatchVMPreview feature for Microsoft.Compute
  # This is a preview feature that is typically not registered by default
  name             = "InGuestPatchVMPreview"
  provider_name    = "Microsoft.Compute"
  enable_telemetry = var.enable_telemetry
}
