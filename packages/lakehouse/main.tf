terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.83"
    }
  }
}

variable "location" {
  type = string
}
variable "application" {
  type = string
}
variable "environment" {
  type = string
}
variable "databricks_vnet_address_space" {
  type = string
}

locals {
  workload = ["lakehouse"]
}

module "naming" {
  source  = "Azure/naming/azurerm"
  version = "0.3.0"
}

module "locations" {
  source   = "azurerm/locations/azure"
  version  = "0.2.4"
  location = var.location
}

module "resource_names" {
  source = "../../modules/resource-name"
  for_each = {
    rg = {
      naming_data = module.naming.resource_group,
    }
    snet = {
      naming_data = module.naming.subnet,
    }
    dbw = {
      naming_data = module.naming.databricks_workspace,
    }
  }
  naming_data   = each.value.naming_data
  location_data = module.locations
  application   = var.application
  workload      = local.workload
  environment   = var.environment
}

module "databricks_access_connector_name" {
  source = "../../modules/resource-name"
  naming_data = {
    slug       = "dbac"
    dashes     = true
    scope      = ""
    max_length = 64
  }
  location_data = module.locations
  application   = var.application
  workload      = local.workload
  environment   = var.environment
}

module "databricks_resource_names" {
  source = "../../modules/resource-name"
  for_each = {
    mrg = {
      naming_data = module.naming.resource_group,
      workload    = ["dbw", "managed"]
    }
    vnet = {
      naming_data = module.naming.virtual_network,
      workload    = ["dbw"]
    }
    nsg = {
      naming_data = module.naming.network_security_group,
      workload    = ["dbw"]
    }
    snet_private = {
      naming_data = module.naming.subnet,
      workload    = ["dbw", "private"]
    }
    snet_public = {
      naming_data = module.naming.subnet,
      workload    = ["dbw", "public"]
    }
  }
  naming_data   = each.value.naming_data
  location_data = module.locations
  application   = var.application
  workload      = each.value.workload
  environment   = var.environment
}

resource "azurerm_resource_group" "this" {
  name     = module.resource_names["rg"].name
  location = var.location
}

resource "azurerm_databricks_access_connector" "this" {
  name                = module.databricks_access_connector_name.name
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  identity {
    type = "SystemAssigned"
  }
}

module "databricks_vnet" {
  source = "../../modules/databricks-vnet"

  resource_group = azurerm_resource_group.this
  resource_names = module.databricks_resource_names
  address_space  = var.databricks_vnet_address_space
}

resource "azurerm_databricks_workspace" "this" {
  name                        = module.resource_names["dbw"].name
  resource_group_name         = azurerm_resource_group.this.name
  location                    = azurerm_resource_group.this.location
  sku                         = "premium"
  managed_resource_group_name = module.databricks_resource_names["mrg"].name

  custom_parameters {
    no_public_ip                                         = true
    virtual_network_id                                   = module.databricks_vnet.vnet.id
    private_subnet_name                                  = module.databricks_vnet.snet_private.name
    public_subnet_name                                   = module.databricks_vnet.snet_public.name
    private_subnet_network_security_group_association_id = module.databricks_vnet.nsga_private.id
    public_subnet_network_security_group_association_id  = module.databricks_vnet.nsga_public.id
  }
}

output "resource_group" {
  value = azurerm_resource_group.this
}
output "databricks_workspace" {
  value = azurerm_databricks_workspace.this
}
output "databricks_access_connector" {
  value = azurerm_databricks_access_connector.this
}
output "databricks_vnet" {
  value = module.databricks_vnet.vnet
}
output "databricks_subnets" {
  value = [
    module.databricks_vnet.snet_private,
    module.databricks_vnet.snet_public
  ]
}
