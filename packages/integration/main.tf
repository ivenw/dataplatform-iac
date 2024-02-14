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
  description = "The environment of the resource group. i.e. `dev`, `test`, `prod`."
  type        = string
}
variable "vsts_config" {
  description = "The configuration for the VSTS integration."
  type = object({
    account_name    = string
    project_name    = string
    repository_name = string
    branch_name     = string
    root_folder     = string
  })
  default = null
}

locals {
  workload = ["integration"]
}

module "locations" {
  source   = "azurerm/locations/azure"
  version  = "0.2.4"
  location = var.location
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
  application   = var.application
  naming_data   = each.value.naming_data
  location_data = module.locations
  environment   = var.environment
  workload      = local.workload
}

data "azurerm_client_config" "this" {}

resource "azurerm_resource_group" "this" {
  name     = module.resource_names["rg"].name
  location = var.location
}

resource "azurerm_data_factory" "this" {
  name                            = module.resource_names["adf"].name
  location                        = azurerm_resource_group.this.location
  resource_group_name             = azurerm_resource_group.this.name
  managed_virtual_network_enabled = true

  global_parameter {
    name  = "environment"
    type  = "String"
    value = var.environment
  }

  identity {
    type = "SystemAssigned"
  }

  # should public_networ_enabled be false?
  dynamic "vsts_configuration" {
    for_each = var.vsts_config != null ? [1] : []

    content {
      # more of this needs be moved into variables and config
      tenant_id       = data.azurerm_client_config.this.tenant_id
      account_name    = var.vsts_config.account_name
      project_name    = var.vsts_config.project_name
      repository_name = var.vsts_config.repository_name
      branch_name     = var.vsts_config.branch_name
      root_folder     = var.vsts_config.root_folder
      # check if we want to have `publishing_enabled` true
    }
  }

  lifecycle {
    ignore_changes = [
      vsts_configuration,
      global_parameter
    ]
  }
}

output "data_factory" {
  value = azurerm_data_factory.this
}

