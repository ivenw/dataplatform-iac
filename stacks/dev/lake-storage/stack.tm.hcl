stack {
  name = "lake-storage-dev"
  id   = "46369ed4-4bbc-41d3-9d9d-dac932e6bb4a"

  after = [
    "../integration",
    "../lakehouse"
  ]
}

generate_hcl "_main.stack.tm.tf" {
  content {
    provider "azurerm" {
      features {}
      tenant_id       = global.tenant_id
      subscription_id = global.subscription_id
    }

    data "terraform_remote_state" "integration" {
      backend = "azurerm"
      config  = tm_merge(global.backend, { key = tm_join(".", [global.environment, global.remote_state_keys.integration]) })
    }

    data "terraform_remote_state" "lakehouse" {
      backend = "azurerm"
      config  = tm_merge(global.backend, { key = tm_join(".", [global.environment, global.remote_state_keys.lakehouse]) })
    }
  }
}
