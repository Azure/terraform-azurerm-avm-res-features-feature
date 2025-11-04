terraform {
  required_version = "~> 1.5"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.21"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }
}

provider "azurerm" {
  features {}
}


## Section to provide a random Azure region for the resource group
# This allows us to randomize the region for the resource group.
module "regions" {
  source  = "Azure/avm-utl-regions/azurerm"
  version = "0.9.0"
}

# Filter regions to only include those suitable for resource groups
locals {
  available_regions = [
    for region in module.regions.regions : region
    if contains([
      "eastus", "eastus2", "westus", "westus2", "westus3", "centralus", "northcentralus", "southcentralus", "westcentralus",
      "northeurope", "westeurope", "francecentral", "germanywestcentral", "switzerlandnorth", "norwayeast",
      "uksouth", "ukwest", "canadacentral", "canadaeast", "brazilsouth",
      "japaneast", "japanwest", "koreacentral", "koreasouth", "eastasia", "southeastasia",
      "australiaeast", "australiasoutheast", "centralindia", "southindia", "westindia"
    ], region.name)
  ]
}

# This allows us to randomize the region for the resource group.
resource "random_integer" "region_index" {
  max = length(local.available_regions) - 1
  min = 0
}
## End of section to provide a random Azure region for the resource group

# This ensures we have unique CAF compliant names for our resources.
module "naming" {
  source  = "Azure/naming/azurerm"
  version = "0.4.1"
}

# This is required for resource modules
resource "azurerm_resource_group" "this" {
  location = local.available_regions[random_integer.region_index.result].name
  name     = module.naming.resource_group.name_unique
}

# This is the module call for feature registration
# Feature registration operates at subscription level, not resource group level
module "test" {
  source = "../../"

  # Register the InGuestPatchVMPreview feature for Microsoft.Compute
  # This is a preview feature that enables in-guest patching for VMs
  name             = "InGuestPatchVMPreview"
  provider_name    = "Microsoft.Compute"
  enable_telemetry = var.enable_telemetry # see variables.tf
}
