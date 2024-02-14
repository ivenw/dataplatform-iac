stack {
  name        = "unity-catalog"
  description = "unity-catalog"
  id          = "9ee92a09-3a68-45f9-8a00-4a988a7efb16"

  after = [
    "../dev/lakehouse",
    "../dev/lake-storage",
    "../prod/lakehouse",
    "../prod/lake-storage"
  ]

}

generate_hcl "_main.stack.tm.tf" {
  content {
    provider "azurerm" {
      features {}
      tenant_id       = global.tenant_id
      subscription_id = global.subscriptions.prod.subscription_id
    }

    provider "databricks" {
      host            = "https://accounts.azuredatabricks.net"
      azure_tenant_id = global.tenant_id


      account_id = global.databricks_account_id
      auth_type  = "azure-cli"
    }

    data "terraform_remote_state" "lake_storage" {
      backend = "azurerm"

      for_each = toset(local.environments)
      config   = merge(local.backend, { key = join(".", [each.value, local.remote_state_keys.lake_storage]) })
    }

    data "terraform_remote_state" "lakehouse" {
      backend = "azurerm"

      for_each = toset(local.environments)
      config   = merge(local.backend, { key = join(".", [each.value, local.remote_state_keys.lakehouse]) })
    }

    tm_dynamic "provider" {
      for_each = global.environments
      iterator = each
      labels   = ["databricks"]

      content {
        alias = each.value
        host  = data.terraform_remote_state.lakehouse[each.value].outputs.databricks_workspace.workspace_url
      }
    }

    // This is a bit ugly but necessary becasue providers can't be dynamically set in a for_each in terraform
    // Only one provider seems to actually be required, so check if we can simplify this
    tm_dynamic "resource" {
      for_each = global.environments
      iterator = each
      labels   = ["databricks_storage_credential", each.value]

      content {
        provider = tm_hcl_expression("databricks.${each.value}")
        name     = data.terraform_remote_state.lakehouse[each.value].outputs.databricks_access_connector.name
        comment  = "Managed by Terraform"
        azure_managed_identity {
          access_connector_id = data.terraform_remote_state.lakehouse[each.value].outputs.databricks_access_connector.id
        }
        depends_on = [databricks_metastore_assignment.this]
      }
    }

    tm_dynamic "resource" {
      for_each = global.environments
      iterator = each
      labels   = ["databricks_external_location", each.value]

      content {
        provider = tm_hcl_expression("databricks.${each.value}")

        name    = "catalog-${each.value}"
        comment = "Managed by Terraform"
        url = format(
          "abfss://%s@%s.dfs.core.windows.net/",
          local.uc_container_name,
          data.terraform_remote_state.lake_storage[each.value].outputs.storage_account_names["lakehouse"]
        )
        credential_name = tm_hcl_expression("databricks_storage_credential.${each.value}.name")
      }
    }

    tm_dynamic "resource" {
      for_each = global.environments
      iterator = each
      labels   = ["databricks_catalog", each.value]

      content {
        provider = tm_hcl_expression("databricks.${each.value}")

        name           = each.value
        comment        = "Managed by Terraform"
        isolation_mode = "ISOLATED"
        storage_root = format(
          "abfss://%s@%s.dfs.core.windows.net/",
          local.uc_container_name,
          data.terraform_remote_state.lake_storage[each.value].outputs.storage_account_names["lakehouse"]
        )
        depends_on = [tm_hcl_expression("resource.databricks_external_location.${each.value}")]
      }
    }
  }
}
