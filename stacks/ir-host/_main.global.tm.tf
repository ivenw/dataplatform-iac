// TERRAMATE: GENERATED AUTOMATICALLY DO NOT EDIT

terraform {
  backend "azurerm" {
    container_name       = "tfstate"
    key                  = "ir-host.tfstate"
    resource_group_name  = "rg-xxxx"
    storage_account_name = "xxxx"
    subscription_id      = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
    tenant_id            = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
  }
}
locals {
  application = ""
  backend = {
    container_name       = "tfstate"
    resource_group_name  = "rg-xxxx"
    storage_account_name = "xxxx"
    subscription_id      = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
    tenant_id            = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
  }
  devtest_environments = [
    "dev",
  ]
  environment = ""
  environments = [
    "dev",
    "prod",
  ]
  location = "swedencentral"
  prod_environments = [
    "prod",
  ]
  remote_state_keys = {
    integration   = "integration.tfstate"
    ir_host       = "ir-host.tfstate"
    lake_network  = "lake-network.tfstate"
    lake_storage  = "lake-storage.tfstate"
    lakehouse     = "lakehouse.tfstate"
    unity_catalog = "unity-catalog.tfstate"
  }
}
