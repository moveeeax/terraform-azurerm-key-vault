terraform {
  required_version = ">= 1.5"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.19, < 5.0"
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

  sku_name = "standard"

  # The module denies network access by default, so callers have to be listed
  # explicitly. Replace this with the public egress range you administer the
  # vault from, or use network_acls_virtual_network_subnet_ids instead.
  network_acls_ip_rules = ["203.0.113.0/24"]

  tags = {
    Environment = "sandbox"
    ManagedBy   = "terraform"
  }
}

output "key_vault_uri" {
  value = module.key_vault.vault_uri
}
