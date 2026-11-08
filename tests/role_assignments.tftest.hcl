# Test-only requirement: `mock_provider` needs Terraform >= 1.7 (or OpenTofu >= 1.7).
# The module itself still supports terraform >= 1.5.

mock_provider "azurerm" {
  mock_data "azurerm_client_config" {
    defaults = {
      tenant_id = "00000000-0000-0000-0000-000000000000"
    }
  }

  # A well-formed vault ID, so anything scoped to the vault plans like it would
  # against Azure instead of receiving a random string.
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

run "no_role_assignments_by_default" {
  command = plan

  assert {
    condition     = length(azurerm_role_assignment.this) == 0
    error_message = "With the default role_assignments = {}, no role assignments may be created, so upgrading the module leaves existing plans unchanged."
  }
}

# Mocked apply: Terraform leaves mocked computed values (the vault ID) unknown
# during plan, so the scope comparison needs apply. Nothing reaches Azure.
run "role_assignments_are_scoped_to_the_vault" {
  command = apply

  variables {
    role_assignments = {
      app = {
        principal_id         = "11111111-1111-1111-1111-111111111111"
        role_definition_name = "Key Vault Secrets User"
        principal_type       = "ServicePrincipal"
      }
      admins = {
        principal_id         = "22222222-2222-2222-2222-222222222222"
        role_definition_name = "Key Vault Administrator"
        description          = "Platform team"
      }
    }
  }

  assert {
    condition     = azurerm_role_assignment.this["app"].scope == azurerm_key_vault.this.id
    error_message = "Role assignments must be scoped to the vault."
  }

  assert {
    condition     = azurerm_role_assignment.this["app"].role_definition_name == "Key Vault Secrets User"
    error_message = "role_definition_name must be passed through."
  }

  assert {
    condition     = azurerm_role_assignment.this["app"].principal_id == "11111111-1111-1111-1111-111111111111"
    error_message = "principal_id must be passed through."
  }

  assert {
    condition     = azurerm_role_assignment.this["app"].principal_type == "ServicePrincipal"
    error_message = "principal_type must be passed through."
  }

  assert {
    condition     = azurerm_role_assignment.this["admins"].description == "Platform team"
    error_message = "description must be passed through."
  }
}

run "rejects_role_assignments_without_rbac" {
  command = plan

  variables {
    enable_rbac_authorization = false
    role_assignments = {
      app = {
        principal_id         = "11111111-1111-1111-1111-111111111111"
        role_definition_name = "Key Vault Secrets User"
      }
    }
  }

  expect_failures = [azurerm_role_assignment.this]
}

run "access_policy_vault_without_assignments_still_plans" {
  command = plan

  variables {
    enable_rbac_authorization = false
  }

  assert {
    condition     = azurerm_key_vault.this.rbac_authorization_enabled == false
    error_message = "The RBAC precondition must not affect vaults that use access policies and request no role assignments."
  }
}

run "rejects_non_key_vault_role" {
  command = plan

  variables {
    role_assignments = {
      app = {
        principal_id         = "11111111-1111-1111-1111-111111111111"
        role_definition_name = "Owner"
      }
    }
  }

  expect_failures = [var.role_assignments]
}

run "rejects_unknown_principal_type" {
  command = plan

  variables {
    role_assignments = {
      app = {
        principal_id         = "11111111-1111-1111-1111-111111111111"
        role_definition_name = "Key Vault Secrets User"
        principal_type       = "ManagedIdentity"
      }
    }
  }

  expect_failures = [var.role_assignments]
}

run "rejects_non_guid_principal_id" {
  command = plan

  variables {
    role_assignments = {
      app = {
        principal_id         = "app@example.com"
        role_definition_name = "Key Vault Secrets User"
      }
    }
  }

  expect_failures = [var.role_assignments]
}
