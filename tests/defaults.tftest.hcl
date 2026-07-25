# Test-only requirement: `mock_provider` needs Terraform >= 1.7 (or OpenTofu >= 1.7).
# The module itself still supports terraform >= 1.5 -- do not raise
# `required_version` in versions.tf on account of this file.
#
# Run with:  terraform test
# No Azure credentials and no network access to Azure are needed.

mock_provider "azurerm" {
  mock_data "azurerm_client_config" {
    defaults = {
      tenant_id = "00000000-0000-0000-0000-000000000000"
    }
  }
}

variables {
  name                = "example-kv-01"
  resource_group_name = "example-rg"
  location            = "eastus"
}

run "defaults_are_safe" {
  command = plan

  assert {
    condition     = azurerm_key_vault.this.purge_protection_enabled == true
    error_message = "purge protection must default to true: without it a soft-deleted vault and every key in it can be purged permanently and unrecoverably."
  }

  assert {
    condition     = azurerm_key_vault.this.soft_delete_retention_days == 90
    error_message = "soft delete retention must default to the 90-day maximum."
  }

  assert {
    condition     = one(azurerm_key_vault.this.network_acls).default_action == "Deny"
    error_message = "network ACL default action must default to Deny; Allow accepts traffic from any source address."
  }

  assert {
    condition     = one(azurerm_key_vault.this.network_acls).bypass == "AzureServices"
    error_message = "network ACL bypass must default to AzureServices."
  }

  assert {
    condition     = azurerm_key_vault.this.enable_rbac_authorization == true
    error_message = "RBAC authorization must default to true rather than legacy vault access policies."
  }

  assert {
    condition     = azurerm_key_vault.this.enabled_for_disk_encryption == false
    error_message = "disk encryption access must stay opt-in."
  }

  assert {
    condition     = azurerm_key_vault.this.sku_name == "standard"
    error_message = "sku_name must default to standard."
  }
}

run "tenant_id_falls_back_to_current_client" {
  command = plan

  assert {
    condition     = azurerm_key_vault.this.tenant_id == data.azurerm_client_config.current.tenant_id
    error_message = "a null tenant_id must resolve to the current client's tenant."
  }
}

run "explicit_tenant_id_wins" {
  command = plan

  variables {
    tenant_id = "11111111-1111-1111-1111-111111111111"
  }

  assert {
    condition     = azurerm_key_vault.this.tenant_id == "11111111-1111-1111-1111-111111111111"
    error_message = "an explicit tenant_id must override the current client's tenant."
  }
}

run "network_rules_are_passed_through" {
  command = plan

  variables {
    network_acls_ip_rules                   = ["203.0.113.0/24"]
    network_acls_virtual_network_subnet_ids = ["/subscriptions/x/resourceGroups/y/providers/Microsoft.Network/virtualNetworks/z/subnets/s"]
  }

  assert {
    condition     = one(azurerm_key_vault.this.network_acls).ip_rules == toset(["203.0.113.0/24"])
    error_message = "network_acls_ip_rules must reach the network_acls block; a Deny default action is unusable otherwise."
  }

  assert {
    condition     = one(azurerm_key_vault.this.network_acls).virtual_network_subnet_ids == toset(["/subscriptions/x/resourceGroups/y/providers/Microsoft.Network/virtualNetworks/z/subnets/s"])
    error_message = "network_acls_virtual_network_subnet_ids must reach the network_acls block."
  }
}
