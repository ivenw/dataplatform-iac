stack {
  name = "lakehouse-prod"
  id   = "b16b029d-f056-49ce-83c7-c042adb0b2a7"
}

generate_hcl "_main.stack.tm.tf" {
  content {
    provider "azurerm" {
      features {}
      tenant_id       = global.tenant_id
      subscription_id = global.subscription_id
    }

    locals {
      databricks_vnet_address_space = global.lakehouse.vnet_address_space.prod
    }
  }
}

