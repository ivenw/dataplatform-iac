locals {
  workload           = ["vault"]
  secret_permissions = ["Get", "List"]
}

module "locations" {
  source   = "azurerm/locations/azure"
  version  = "0.2.4"
  location = local.location
}

module "naming" {
  source  = "Azure/naming/azurerm"
  version = "0.3.0"
}

module "resource_names" {
  source = "../../modules/resource-name"
  for_each = {
    rg = {
      naming_data = module.naming.resource_group,
    }
    kv = {
      naming_data = module.naming.key_vault,
    }
  }
  naming_data   = each.value.naming_data
  location_data = module.locations
  application   = local.application
  workload      = local.workload
}

resource "azurerm_resource_group" "this" {
  name     = module.resource_names["rg"].name
  location = local.location
}

data "azurerm_client_config" "this" {}

resource "azurerm_key_vault" "this" {
  name                = module.resource_names["kv"].name
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  tenant_id           = data.azurerm_client_config.this.tenant_id
  sku_name            = "standard"
}

resource "azurerm_key_vault_access_policy" "integration" {
  for_each = data.terraform_remote_state.integration

  tenant_id          = data.azurerm_client_config.this.tenant_id
  key_vault_id       = azurerm_key_vault.this.id
  object_id          = each.value.outputs.data_factory.identity[0].principal_id
  secret_permissions = local.secret_permissions
}

output "key_vault" {
  value = azurerm_key_vault.this
}
