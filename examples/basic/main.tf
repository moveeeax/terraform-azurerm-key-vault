terraform {
  required_version = ">= 1.5"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.0"
    }
  }
}

provider "azurerm" {
  features {}
}

module "key_vault" {
  source = "../.."

  name                = "example-kv-01"
  resource_group_name = "example-rg"
  location            = "eastus"

  sku_name                 = "standard"
  purge_protection_enabled = true

  tags = {
    Environment = "sandbox"
    ManagedBy   = "terraform"
  }
}

output "key_vault_uri" {
  value = module.key_vault.vault_uri
}
