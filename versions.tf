terraform {
  required_version = ">= 1.5"

  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      # Lower bound: `public_network_access_enabled` was added to
      # `azurerm_key_vault` in azurerm 3.19.0. Anything older fails with
      # "Unsupported argument".
      # Upper bound: `enable_rbac_authorization` is deprecated in 4.x and is
      # scheduled for removal in azurerm 5.0.
      version = ">= 3.19, < 5.0"
    }
  }
}
