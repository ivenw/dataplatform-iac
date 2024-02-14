locals {
  workload = ["lake", "network"]
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
    vnet = {
      naming_data = module.naming.virtual_network,
    }
    nsg = {
      naming_data = module.naming.network_security_group,
    }
  }
  naming_data   = each.value.naming_data
  location_data = module.locations
  application   = local.application
  workload      = local.workload
}

module "subnet_names" {
  source        = "../../modules/resource-name"
  for_each      = local.subnet_data
  naming_data   = module.naming.subnet
  location_data = module.locations
  application   = local.application
  workload      = concat(local.workload, [each.value.workload])
  environment   = each.value.environment
}

module "private_endpoint_names" {
  source        = "../../modules/resource-name"
  for_each      = local.subnet_data
  naming_data   = module.naming.private_endpoint
  location_data = module.locations
  application   = local.application
  workload      = concat(local.workload, [each.value.workload])
  environment   = each.value.environment
}

resource "azurerm_resource_group" "this" {
  name     = module.resource_names["rg"].name
  location = local.location
}

resource "azurerm_virtual_network" "this" {
  name                = module.resource_names["vnet"].name
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  address_space       = [local.address_space]
}

resource "azurerm_network_security_group" "this" {
  name                = module.resource_names["nsg"].name
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
}

resource "azurerm_subnet" "this" {
  for_each             = local.subnet_data
  name                 = module.subnet_names[each.key].name
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = [cidrsubnet(local.address_space, 4, each.value.snet_idx)]
}

resource "azurerm_private_endpoint" "this" {
  for_each = local.subnet_data

  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  subnet_id           = azurerm_subnet.this[each.key].id
  name                = module.private_endpoint_names[each.key].name

  private_service_connection {
    name                           = "storage-account-blob"
    private_connection_resource_id = data.terraform_remote_state.lake_storage[each.value.environment].outputs.storage_account_ids[each.value.workload]
    subresource_names              = ["blob"]
    is_manual_connection           = false
  }
}

resource "azurerm_virtual_network_peering" "to_remote" {
  for_each = toset(local.environments)

  name                      = "this-to-${data.terraform_remote_state.lakehouse[each.value].outputs.databricks_vnet.name}"
  resource_group_name       = azurerm_virtual_network.this.resource_group_name
  virtual_network_name      = azurerm_virtual_network.this.name
  remote_virtual_network_id = data.terraform_remote_state.lakehouse[each.value].outputs.databricks_vnet.id
}

resource "azurerm_virtual_network_peering" "from_remote_prod" {
  for_each = toset(local.prod_environments)

  name                      = "this-to-${azurerm_virtual_network.this.name}"
  resource_group_name       = data.terraform_remote_state.lakehouse[each.value].outputs.databricks_vnet.resource_group_name
  virtual_network_name      = data.terraform_remote_state.lakehouse[each.value].outputs.databricks_vnet.name
  remote_virtual_network_id = azurerm_virtual_network.this.id
}

resource "azurerm_virtual_network_peering" "from_remote_devtest" {
  provider = azurerm.devtest

  for_each = toset(local.devtest_environments)

  name                      = "this-to-${azurerm_virtual_network.this.name}"
  resource_group_name       = data.terraform_remote_state.lakehouse[each.value].outputs.databricks_vnet.resource_group_name
  virtual_network_name      = data.terraform_remote_state.lakehouse[each.value].outputs.databricks_vnet.name
  remote_virtual_network_id = azurerm_virtual_network.this.id
}

output "vnet" {
  value = azurerm_virtual_network.this
}
output "network_security_group" {
  value = azurerm_network_security_group.this
}

