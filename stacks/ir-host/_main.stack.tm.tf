// TERRAMATE: GENERATED AUTOMATICALLY DO NOT EDIT

provider "azurerm" {
  subscription_id = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
  tenant_id       = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
  features {
  }
}
data "terraform_remote_state" "integration" {
  backend = "azurerm"
  config = merge(local.backend, {
    key = join(".", [
      each.value,
      local.remote_state_keys.integration,
    ])
  })
  for_each = toset(local.environments)
}
