module "integration" {
  source      = "../../../packages/integration"
  location    = local.location
  application = local.application
  environment = local.environment
}

output "data_factory" {
  value = module.integration.data_factory
}
