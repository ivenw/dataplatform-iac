module "lake_storage" {
  source = "../../../packages/lake-storage"

  location     = local.location
  application  = local.application
  environment  = local.environment
  data_factory = data.terraform_remote_state.integration.outputs.data_factory
  databricks_subnets = {
    for env in local.environments : env => data.terraform_remote_state.lakehouse[env].outputs.databricks_subnets
  }
  databricks_access_connectors = {
    for env in local.environments : env => data.terraform_remote_state.lakehouse[env].outputs.databricks_access_connector
  }
}


output "storage_account_ids" {
  value = {
    landing   = module.lake_storage.storage_accounts["landing"].id
    lakehouse = module.lake_storage.storage_accounts["lakehouse"].id
  }
}
output "storage_account_names" {
  value = {
    landing   = module.lake_storage.storage_accounts["landing"].name
    lakehouse = module.lake_storage.storage_accounts["lakehouse"].name
  }
}

