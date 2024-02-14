stack {
  name = "integration-prod"
  id   = "1624d2e8-fe7a-48d9-93c6-2af36fae400e"
}

generate_hcl "_main.stack.tm.tf" {
  content {
    provider "azurerm" {
      features {}
      tenant_id       = global.tenant_id
      subscription_id = global.subscription_id
    }
  }
}
