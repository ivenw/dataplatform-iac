stack {
  name = "lake-network"
  id   = "15aaa70c-bf04-45f9-a519-639b9b1f850f"

  after = [
    "../dev/lake-storage",
    "../dev/lakehouse",
    "../prod/lake-storage",
    "../prod/lakehouse"
  ]
}

generate_hcl "_main.stack.tm.tf" {
  content {
    provider "azurerm" {
      features {}
      tenant_id       = global.tenant_id
      subscription_id = global.subscriptions.prod.subscription_id
    }

    provider "azurerm" {
      features {}
      alias           = "devtest"
      tenant_id       = global.tenant_id
      subscription_id = global.subscriptions.devtest.subscription_id
    }

    locals {
      address_space = global.lake_network.address_space
      subnet_data   = global.lake_network.subnet_data
    }

    data "terraform_remote_state" "lake_storage" {
      for_each = toset(local.environments)

      backend = "azurerm"
      config = merge(local.backend, { key = join(
        ".", [each.value, local.remote_state_keys.lake_storage]
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

