// TERRAMATE: GENERATED AUTOMATICALLY DO NOT EDIT

provider "azurerm" {
  subscription_id = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
  tenant_id       = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
  features {
  }
}
data "terraform_remote_state" "integration" {
  backend = "azurerm"
  config = {
    container_name       = "tfstate"
    key                  = "dev.integration.tfstate"
    resource_group_name  = "rg-xxxx"
    storage_account_name = "xxxx"
    subscription_id      = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
    tenant_id            = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
  }
}
data "terraform_remote_state" "lakehouse" {
  backend = "azurerm"
  config = {
    container_name       = "tfstate"
    key                  = "dev.lakehouse.tfstate"
    resource_group_name  = "rg-xxxx"
    storage_account_name = "xxxx"
    subscription_id      = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
    tenant_id            = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
  }
}
