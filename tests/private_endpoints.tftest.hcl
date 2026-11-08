# Test-only requirement: `mock_provider` needs Terraform >= 1.7 (or OpenTofu >= 1.7).
# The module itself still supports terraform >= 1.5.

mock_provider "azurerm" {
  mock_data "azurerm_client_config" {
    defaults = {
      tenant_id = "00000000-0000-0000-0000-000000000000"
    }
  }

  # A well-formed vault ID, so the endpoint's private_connection_resource_id
  # looks like it would against Azure instead of a random string.
  mock_resource "azurerm_key_vault" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/example-rg/providers/Microsoft.KeyVault/vaults/example-kv-01"
    }
  }
}

variables {
  name                = "example-kv-01"
  resource_group_name = "example-rg"
  location            = "eastus"
}

run "no_private_endpoints_by_default" {
  command = plan

  assert {
    condition     = length(azurerm_private_endpoint.this) == 0
    error_message = "With the default private_endpoints = {}, no private endpoints may be created, so upgrading the module leaves existing plans unchanged."
  }

  assert {
    condition     = azurerm_key_vault.this.public_network_access_enabled == true
    error_message = "public_network_access_enabled must keep its default."
  }
}

# Mocked apply: Terraform leaves mocked computed values (the vault ID) unknown
# during plan, so the connection target can only be compared after apply.
# Nothing reaches Azure.
run "private_endpoint_targets_the_vault" {
  command = apply

  variables {
    private_endpoints = {
      hub = {
        subnet_id            = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/net-rg/providers/Microsoft.Network/virtualNetworks/hub/subnets/private-endpoints"
        private_dns_zone_ids = ["/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/dns-rg/providers/Microsoft.Network/privateDnsZones/privatelink.vaultcore.azure.net"]
      }
      spoke = {
        subnet_id           = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/net-rg/providers/Microsoft.Network/virtualNetworks/spoke/subnets/pe"
        name                = "kv-spoke-pe"
        resource_group_name = "net-rg"
        location            = "westeurope"
      }
    }
  }

  assert {
    condition     = azurerm_private_endpoint.this["hub"].name == "example-kv-01-pe-hub"
    error_message = "name must default to <vault name>-pe-<key>."
  }

  assert {
    condition     = azurerm_private_endpoint.this["hub"].resource_group_name == "example-rg" && azurerm_private_endpoint.this["hub"].location == "eastus"
    error_message = "resource_group_name and location must default to the vault's."
  }

  assert {
    condition     = azurerm_private_endpoint.this["hub"].private_service_connection[0].private_connection_resource_id == azurerm_key_vault.this.id
    error_message = "The private service connection must target the vault."
  }

  assert {
    condition     = azurerm_private_endpoint.this["hub"].private_service_connection[0].subresource_names == tolist(["vault"])
    error_message = "The private service connection must use the vault sub-resource."
  }

  assert {
    condition     = azurerm_private_endpoint.this["hub"].private_service_connection[0].is_manual_connection == false
    error_message = "The connection must be automatic; the module owns both sides."
  }

  assert {
    condition     = azurerm_private_endpoint.this["hub"].private_dns_zone_group[0].private_dns_zone_ids == tolist(["/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/dns-rg/providers/Microsoft.Network/privateDnsZones/privatelink.vaultcore.azure.net"])
    error_message = "private_dns_zone_ids must reach the DNS zone group."
  }

  assert {
    condition     = length(azurerm_private_endpoint.this["spoke"].private_dns_zone_group) == 0
    error_message = "No DNS zone group may be created when private_dns_zone_ids is null."
  }

  assert {
    condition     = azurerm_private_endpoint.this["spoke"].name == "kv-spoke-pe" && azurerm_private_endpoint.this["spoke"].resource_group_name == "net-rg" && azurerm_private_endpoint.this["spoke"].location == "westeurope"
    error_message = "Explicit name, resource_group_name and location must be passed through."
  }

  assert {
    condition     = azurerm_key_vault.this.public_network_access_enabled == true
    error_message = "Adding a private endpoint must not change public_network_access_enabled."
  }

  assert {
    condition     = output.private_endpoints["hub"].id == azurerm_private_endpoint.this["hub"].id
    error_message = "The private_endpoints output must expose each endpoint's ID."
  }
}

run "empty_dns_zone_list_creates_no_zone_group" {
  command = plan

  variables {
    private_endpoints = {
      hub = {
        subnet_id            = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/net-rg/providers/Microsoft.Network/virtualNetworks/hub/subnets/pe"
        private_dns_zone_ids = []
      }
    }
  }

  assert {
    condition     = length(azurerm_private_endpoint.this["hub"].private_dns_zone_group) == 0
    error_message = "An empty private_dns_zone_ids list must not create a DNS zone group."
  }
}

run "rejects_malformed_subnet_id" {
  command = plan

  variables {
    private_endpoints = {
      hub = {
        subnet_id = "private-endpoints"
      }
    }
  }

  expect_failures = [var.private_endpoints]
}

run "rejects_malformed_dns_zone_id" {
  command = plan

  variables {
    private_endpoints = {
      hub = {
        subnet_id            = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/net-rg/providers/Microsoft.Network/virtualNetworks/hub/subnets/pe"
        private_dns_zone_ids = ["privatelink.vaultcore.azure.net"]
      }
    }
  }

  expect_failures = [var.private_endpoints]
}
