stack {
  name        = "ir-host"
  description = "ir-host"
  id          = "f22839e2-aca9-4509-a9d4-83da26102195"

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
  }
}

