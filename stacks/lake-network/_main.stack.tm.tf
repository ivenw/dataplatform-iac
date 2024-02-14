// TERRAMATE: GENERATED AUTOMATICALLY DO NOT EDIT

provider "azurerm" {
  subscription_id = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
  tenant_id       = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
  features {
  }
}
provider "azurerm" {
  alias           = "devtest"
  subscription_id = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
  tenant_id       = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
  features {
  }
}
locals {
  address_space = "172.24.0.0/24"
  subnet_data = {
    lakehouse_dev = {
      environment = "dev"
      snet_idx    = 1
      workload    = "lakehouse"
    }
    lakehouse_prod = {
      environment = "prod"
      snet_idx    = 2
      workload    = "lakehouse"
    }
    landing_prod = {
      environment = "prod"
      snet_idx    = 0
      workload    = "landing"
    }
  }
}
data "terraform_remote_state" "lake_storage" {
  backend = "azurerm"
  config = merge(local.backend, {
    key = join(".", [
      each.value,
      local.remote_state_keys.lake_storage,
    ])
  })
  for_each = toset(local.environments)
}
data "terraform_remote_state" "lakehouse" {
  backend = "azurerm"
  config = merge(local.backend, {
    key = join(".", [
      each.value,
      local.remote_state_keys.lakehouse,
    ])
  })
  for_each = toset(local.environments)
}
