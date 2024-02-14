module "integration" {
  source      = "../../../packages/integration"
  location    = local.location
  application = local.application
  environment = local.environment
  vsts_config = local.vsts_config
}

output "data_factory" {
  value = module.integration.data_factory
}

