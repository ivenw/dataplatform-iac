stack {
  name = "integration-dev"
  id   = "62a7fd7c-2012-4916-a79e-99145d777dbd"
}

globals {
  environment = "dev"
}

generate_hcl "_main.stack.tm.tf" {
  content {
    provider "azurerm" {
      features {}
      tenant_id       = global.tenant_id
      subscription_id = global.subscription_id
    }

    locals {
      vsts_config = global.integration.vsts_config
    }
  }
}

