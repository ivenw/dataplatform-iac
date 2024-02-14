generate_hcl "_main.global.tm.tf" {
  content {
    terraform {
      backend "azurerm" {
        tenant_id            = global.backend.tenant_id
        subscription_id      = global.backend.subscription_id
        resource_group_name  = global.backend.resource_group_name
        storage_account_name = global.backend.storage_account_name
        container_name       = global.backend.container_name
        key                  = tm_join(".", tm_compact([global.environment, terramate.stack.path.basename, "tfstate"]))
      }
    }

    locals {
      backend              = global.backend
      remote_state_keys    = global.remote_state_keys
      location             = global.location
      application          = global.application
      environment          = global.environment
      environments         = global.environments
      devtest_environments = global.subscriptions.devtest.environments
      prod_environments    = global.subscriptions.prod.environments
    }
  }
}

