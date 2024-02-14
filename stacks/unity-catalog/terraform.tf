terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.79"
    }
    databricks = {
      source  = "databricks/databricks"
      version = "~> 1.29"
    }
  }
}

