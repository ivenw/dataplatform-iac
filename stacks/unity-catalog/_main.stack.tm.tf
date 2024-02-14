// TERRAMATE: GENERATED AUTOMATICALLY DO NOT EDIT

provider "azurerm" {
  subscription_id = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
  tenant_id       = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
  features {
  }
}
provider "databricks" {
  account_id      = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
  auth_type       = "azure-cli"
  azure_tenant_id = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
  host            = "https://accounts.azuredatabricks.net"
}
data "terraform_remote_state" "lake_storage" {
  backend = "azurerm"
  config = merge(local.backend, {
    key = join(".", [
      each.value,
      local.remote_state_keys.lake_storage,
    ])
  })
  for_each = toset(local.environments)
}
data "terraform_remote_state" "lakehouse" {
  backend = "azurerm"
  config = merge(local.backend, {
    key = join(".", [
      each.value,
      local.remote_state_keys.lakehouse,
    ])
  })
  for_each = toset(local.environments)
}
provider "databricks" {
  alias = "dev"
  host  = data.terraform_remote_state.lakehouse["dev"].outputs.databricks_workspace.workspace_url
}
provider "databricks" {
  alias = "prod"
  host  = data.terraform_remote_state.lakehouse["prod"].outputs.databricks_workspace.workspace_url
}
resource "databricks_storage_credential" "dev" {
  comment = "Managed by Terraform"
  depends_on = [
    databricks_metastore_assignment.this,
  ]
  name     = data.terraform_remote_state.lakehouse["dev"].outputs.databricks_access_connector.name
  provider = databricks.dev
  azure_managed_identity {
    access_connector_id = data.terraform_remote_state.lakehouse["dev"].outputs.databricks_access_connector.id
  }
}
resource "databricks_storage_credential" "prod" {
  comment = "Managed by Terraform"
  depends_on = [
    databricks_metastore_assignment.this,
  ]
  name     = data.terraform_remote_state.lakehouse["prod"].outputs.databricks_access_connector.name
  provider = databricks.prod
  azure_managed_identity {
    access_connector_id = data.terraform_remote_state.lakehouse["prod"].outputs.databricks_access_connector.id
  }
}
resource "databricks_external_location" "dev" {
  comment         = "Managed by Terraform"
  credential_name = databricks_storage_credential.dev.name
  name            = "catalog-dev"
  provider        = databricks.dev
  url             = format("abfss://%s@%s.dfs.core.windows.net/", local.uc_container_name, data.terraform_remote_state.lake_storage["dev"].outputs.storage_account_names["lakehouse"])
}
resource "databricks_external_location" "prod" {
  comment         = "Managed by Terraform"
  credential_name = databricks_storage_credential.prod.name
  name            = "catalog-prod"
  provider        = databricks.prod
  url             = format("abfss://%s@%s.dfs.core.windows.net/", local.uc_container_name, data.terraform_remote_state.lake_storage["prod"].outputs.storage_account_names["lakehouse"])
}
resource "databricks_catalog" "dev" {
  comment = "Managed by Terraform"
  depends_on = [
    resource.databricks_external_location.dev,
  ]
  isolation_mode = "ISOLATED"
  name           = "dev"
  provider       = databricks.dev
  storage_root   = format("abfss://%s@%s.dfs.core.windows.net/", local.uc_container_name, data.terraform_remote_state.lake_storage["dev"].outputs.storage_account_names["lakehouse"])
}
resource "databricks_catalog" "prod" {
  comment = "Managed by Terraform"
  depends_on = [
    resource.databricks_external_location.prod,
  ]
  isolation_mode = "ISOLATED"
  name           = "prod"
  provider       = databricks.prod
  storage_root   = format("abfss://%s@%s.dfs.core.windows.net/", local.uc_container_name, data.terraform_remote_state.lake_storage["prod"].outputs.storage_account_names["lakehouse"])
}
