stack {
  name = "lake-storage-prod"
  id   = "6caabe17-5a0d-4c11-afe9-cfc5dccd8626"

  after = [
    "../integration",
    "../lakehouse",
    "../../dev/lakehouse"
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
      for_each = toset(local.environments)

      backend = "azurerm"
      config = merge(local.backend, { key = join(
        ".", [each.value, local.remote_state_keys.lakehouse]
      ) })
    }
  }
}
