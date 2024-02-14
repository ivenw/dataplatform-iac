module "lakehouse" {
  source                        = "../../../packages/lakehouse"
  location                      = local.location
  application                   = local.application
  environment                   = local.environment
  databricks_vnet_address_space = local.databricks_vnet_address_space
}

output "databricks_vnet" {
  value = module.lakehouse.databricks_vnet
}
output "databricks_access_connector" {
  value = module.lakehouse.databricks_access_connector
}
output "databricks_workspace" {
  value = module.lakehouse.databricks_workspace
}
output "databricks_subnets" {
  value = module.lakehouse.databricks_subnets
}
