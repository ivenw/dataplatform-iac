terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.83"
    }
  }
}

locals {
  workload = ["ir", "host"]
}

module "locations" {
  source   = "azurerm/locations/azure"
  version  = "0.2.4"
  location = local.location
}

module "naming" {
  source  = "Azure/naming/azurerm"
  version = "0.3.0"
}

module "resource_names" {
  source = "../../modules/resource-name"
  for_each = {
    rg = {
      naming_data = module.naming.resource_group,
    }
    adf = {
      naming_data = module.naming.data_factory,
    }
  }
  application   = local.application
  naming_data   = each.value.naming_data
  location_data = module.locations
  workload      = local.workload
}

module "ir_resource_names" {
  source = "../../modules/resource-name"
  for_each = {
    on_prem_hub_ir = {
      naming_data = merge(module.naming.data_factory_integration_runtime_managed, { slug = "opir" }),
      workload    = ["on", "prem", "hub"]
    }
  }
  application   = local.application
  naming_data   = each.value.naming_data
  location_data = module.locations
  workload      = each.value.workload
}

resource "azurerm_resource_group" "this" {
  name     = module.resource_names["rg"].name
  location = local.location
}

resource "azurerm_data_factory" "this" {
  name                            = module.resource_names["adf"].name
  location                        = azurerm_resource_group.this.location
  resource_group_name             = azurerm_resource_group.this.name
  managed_virtual_network_enabled = true

  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_role_assignment" "this" {
  for_each = data.terraform_remote_state.integration

  scope                = azurerm_data_factory.this.id
  role_definition_name = "Contributor"
  principal_id         = each.value.outputs.data_factory.identity[0].principal_id
}

resource "azurerm_data_factory_integration_runtime_self_hosted" "this" {
  for_each = module.ir_resource_names

  name            = each.value.name
  data_factory_id = azurerm_data_factory.this.id
}
