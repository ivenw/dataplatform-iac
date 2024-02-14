terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.83"
    }
    azapi = {
      source  = "azure/azapi"
      version = "~> 1.10"
    }
  }
}

variable "resource_group" {
  type = object({
    name     = string
    location = string
  })
}
variable "name" {
  description = "The name of the storage account."
  type        = string
}
variable "container_names" {
  type    = list(string)
  default = []
}
variable "allowed_subnets" {
  type = list(object({
    id = string
  }))
  default = []
}
variable "private_link_resources" {
  type = list(object({
    id = string
  }))
  default = []
}

resource "azurerm_storage_account" "this" {
  name                     = var.name
  resource_group_name      = var.resource_group.name
  location                 = var.resource_group.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  is_hns_enabled           = true

  network_rules {
    default_action             = "Deny"
    ip_rules                   = []
    virtual_network_subnet_ids = [for subnet in var.allowed_subnets : subnet.id]

    dynamic "private_link_access" {
      for_each = var.private_link_resources

      content {
        endpoint_resource_id = private_link_access.value.id
      }
    }
  }
}

// We have to use the azapi provider because the storage account does not permit public access
// and the azurerm provider does not support creating blob containers without public access.
resource "azapi_resource" "blob_containers" {
  for_each  = toset(var.container_names)
  type      = "Microsoft.Storage/storageAccounts/blobServices/containers@2022-09-01"
  name      = each.value
  parent_id = "${azurerm_storage_account.this.id}/blobServices/default"
  body = jsonencode({
    properties = {
      defaultEncryptionScope      = "$account-encryption-key"
      denyEncryptionScopeOverride = false
      metadata                    = {}
      publicAccess                = "None"
    }
  })
}

output "storage_account" {
  value = azurerm_storage_account.this
}
