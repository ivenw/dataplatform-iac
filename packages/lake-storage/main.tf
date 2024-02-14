terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.83"
    }
  }
}

variable "application" {
  type = string
}
variable "location" {
  type = string
}
variable "environment" {
  type = string
}
variable "data_factory" {
  type = object({
    id = string
    identity = list(object({
      principal_id = string
    }))
  })
}
variable "databricks_subnets" {
  type = map(list(object({
    id = string
  })))
}
variable "databricks_access_connectors" {
  type = map(object({
    id = string
    identity = list(object({
      principal_id = string
    }))
  }))
}

locals {
  is_prod = var.environment == "prod"
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
      naming_data = module.naming.resource_group
      workload    = ["lake", "storage"]
    }
    st_landing = {
      naming_data = module.naming.storage_account,
      workload    = ["landing"]
    }
    st_lakehouse = {
      naming_data = module.naming.storage_account,
      workload    = ["lakehouse"]
    }
  }
  naming_data   = each.value.naming_data
  location_data = module.locations
  application   = var.application
  environment   = var.environment
  workload      = each.value.workload
}

resource "azurerm_resource_group" "this" {
  name     = module.resource_names["rg"].name
  location = var.location
}

module "storage_landing" {
  source = "../../modules/lake-storage"

  name           = module.resource_names["st_landing"].name
  resource_group = azurerm_resource_group.this

  allowed_subnets = local.is_prod ? flatten(values(var.databricks_subnets)) : []
  private_link_resources = concat(
    [var.data_factory],
    local.is_prod ? values(var.databricks_access_connectors) : []
  )
}

resource "azurerm_role_assignment" "adf_landing_contributor" {
  scope                = module.storage_landing.storage_account.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = var.data_factory.identity[0].principal_id
}

resource "azurerm_role_assignment" "dbw_landing_read" {
  for_each = local.is_prod ? var.databricks_access_connectors : {}

  scope                = module.storage_landing.storage_account.id
  role_definition_name = "Storage Blob Data Reader"
  principal_id         = each.value.identity[0].principal_id
}

module "storage_lakehouse" {
  source = "../../modules/lake-storage"

  name                   = module.resource_names["st_lakehouse"].name
  resource_group         = azurerm_resource_group.this
  allowed_subnets        = var.databricks_subnets[var.environment]
  private_link_resources = [var.databricks_access_connectors[var.environment]]
  container_names        = ["unity-catalog"]
}

resource "azurerm_role_assignment" "dbw_lakehouse_contributor" {
  scope                = module.storage_lakehouse.storage_account.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = var.databricks_access_connectors[var.environment].identity[0].principal_id
}

output "storage_accounts" {
  value = {
    landing   = module.storage_landing.storage_account
    lakehouse = module.storage_lakehouse.storage_account
  }
}

