terraform {
  required_version = ">= 1.5"

  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      # Lower bound: `rbac_authorization_enabled` (the replacement for
      # `enable_rbac_authorization`, which azurerm 5.0 removed) was added to
      # `azurerm_key_vault` in azurerm 4.42.0. Verified by validating against
      # 4.41.0 (fails) and 4.42.0 (passes).
      # Upper bound: tested against 5.x; 6.0 has not been vetted.
      version = ">= 4.42.0, < 6.0"
    }
  }
}
