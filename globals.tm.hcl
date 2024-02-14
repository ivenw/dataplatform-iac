globals {
  location    = "swedencentral" // Azure region
  application = "" // shorthand for the application i.e. "dp" for Data Platform

  tenant_id             = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx" 
  databricks_account_id = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"

  subscriptions = {
    devtest = {
      subscription_id = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
      environments = [
        "dev"
      ]
    }
    prod = {
      subscription_id = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
      environments = [
        "prod"
      ]
    }
  }
  environment = "" // Leave empty
  environments = tm_concat(global.subscriptions.devtest.environments, global.subscriptions.prod.environments)

  backend = {
    tenant_id            = global.tenant_id
    subscription_id      = global.subscriptions.devtest.subscription_id
    resource_group_name  = "rg-xxxx" // Resource group of the storage account holding the tfstate files
    storage_account_name = "xxxx"
    container_name       = "tfstate" // Recommended container name for tfstate files
  }

  // Remote state keys for the different modules
  remote_state_keys = {
    integration   = "integration.tfstate"
    lake_storage  = "lake-storage.tfstate"
    lakehouse     = "lakehouse.tfstate"
    lake_network  = "lake-network.tfstate"
    unity_catalog = "unity-catalog.tfstate"
    ir_host = "ir-host.tfstate"
  }

  lake_network = {
    address_space = "172.24.0.0/24" // Prefix should be <= /26
    subnet_data = {
      landing_prod = {
        workload    = "landing",
        environment = "prod",
        snet_idx    = 0
      },
      lakehouse_dev = {
        workload    = "lakehouse",
        environment = "dev",
        snet_idx    = 1
      },
      lakehouse_prod = {
        workload    = "lakehouse",
        environment = "prod",
        snet_idx    = 2
      }
    }
  }

  integration = {
        // Azure DevOps configuration for the dev Data Factory
    vsts_config = {
      account_name    = ""
      project_name    = ""
      repository_name = ""
      branch_name     = "main"
      root_folder     = "/"
    }
  }

  lakehouse = {
    vnet_address_space = {   // Prefix should be <= /22
      dev  = "172.24.8.0/21" // 2048 addresses, 1024 nodes
      prod = "172.24.16.0/21"
    }
  }
}
