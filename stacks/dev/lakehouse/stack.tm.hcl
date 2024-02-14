stack {
  name = "lakehouse-dev"
  id   = "9ac577ef-4d19-4abf-9502-6865b88629ed"
}

generate_hcl "_main.stack.tm.tf" {
  content {
    provider "azurerm" {
      features {}
      tenant_id       = global.tenant_id
      subscription_id = global.subscription_id
    }

    locals {
      databricks_vnet_address_space = global.lakehouse.vnet_address_space.dev
    }
  }
}

