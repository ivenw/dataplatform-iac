locals {
  workload          = ["uc"]
  uc_container_name = "unity-catalog"
}

module "naming" {
  source  = "Azure/naming/azurerm"
  version = "0.3.0"
}

module "locations" {
  source   = "azurerm/locations/azure"
  version  = "0.2.4"
  location = local.location
}

module "resource_names" {
  source = "../../modules/resource-name"
  for_each = {
    rg = {
      naming_data = module.naming.resource_group,
    }
    st = {
      naming_data = module.naming.storage_account
    }
  }

  application   = local.application
  workload      = local.workload
  naming_data   = each.value.naming_data
  location_data = module.locations
}

resource "azurerm_resource_group" "this" {
  name     = module.resource_names["rg"].name
  location = local.location
}

module "st" {
  source = "../../modules/lake-storage"

  resource_group  = azurerm_resource_group.this
  name            = module.resource_names["st"].name
  container_names = [local.uc_container_name]
}

resource "databricks_metastore" "this" {
  name          = join("-", ["uc", module.locations.location.short_name])
  storage_root  = format("abfss://%s@%s.dfs.core.windows.net/", local.uc_container_name, module.st.storage_account.name)
  force_destroy = true
  region        = azurerm_resource_group.this.location
}

resource "databricks_metastore_assignment" "this" {
  for_each = toset(local.environments)

  metastore_id         = databricks_metastore.this.id
  workspace_id         = data.terraform_remote_state.lakehouse[each.value].outputs.databricks_workspace.workspace_id
  default_catalog_name = "hive_metastore"
}

