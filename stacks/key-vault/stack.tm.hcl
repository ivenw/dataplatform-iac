stack {
  name = "key-vault"
  id   = "1c5abe3a-fb37-446c-b4e6-c8a2172b6acf"

  after = [
    "../dev/integration",
    "../prod/integration",
  ]
}

generate_hcl "_main.stack.tm.tf" {
  content {
    provider "azurerm" {
      features {}
      tenant_id       = global.tenant_id
      subscription_id = global.subscriptions.prod.subscription_id
    }

    data "terraform_remote_state" "integration" {
      for_each = toset(local.environments)

      backend = "azurerm"
      config = merge(local.backend, { key = join(
        ".", [each.value, local.remote_state_keys.integration]
      ) })
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

