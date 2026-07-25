# Test-only requirement: `mock_provider` needs Terraform >= 1.7 (or OpenTofu >= 1.7).
# The module itself still supports terraform >= 1.5.

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

run "rejects_short_name" {
  command = plan

  variables {
    name = "kv"
  }

  expect_failures = [var.name]
}

run "rejects_overlong_name" {
  command = plan

  variables {
    name = "kv-this-name-is-far-too-long"
  }

  expect_failures = [var.name]
}

run "rejects_name_starting_with_digit" {
  command = plan

  variables {
    name = "1example-kv"
  }

  expect_failures = [var.name]
}

run "rejects_name_with_consecutive_hyphens" {
  command = plan

  variables {
    name = "example--kv"
  }

  expect_failures = [var.name]
}

run "rejects_invalid_sku" {
  command = plan

  variables {
    sku_name = "Standard"
  }

  expect_failures = [var.sku_name]
}

run "rejects_retention_below_minimum" {
  command = plan

  variables {
    soft_delete_retention_days = 6
  }

  expect_failures = [var.soft_delete_retention_days]
}

run "rejects_retention_above_maximum" {
  command = plan

  variables {
    soft_delete_retention_days = 91
  }

  expect_failures = [var.soft_delete_retention_days]
}

run "rejects_fractional_retention" {
  command = plan

  variables {
    soft_delete_retention_days = 7.5
  }

  expect_failures = [var.soft_delete_retention_days]
}

run "rejects_invalid_network_acls_bypass" {
  command = plan

  variables {
    network_acls_bypass = "AzureServices,None"
  }

  expect_failures = [var.network_acls_bypass]
}

run "rejects_invalid_network_acls_default_action" {
  command = plan

  variables {
    network_acls_default_action = "deny"
  }

  expect_failures = [var.network_acls_default_action]
}

run "accepts_valid_non_default_combination" {
  command = plan

  variables {
    sku_name                    = "premium"
    soft_delete_retention_days  = 7
    network_acls_bypass         = "None"
    network_acls_default_action = "Allow"
  }

  assert {
    condition     = azurerm_key_vault.this.sku_name == "premium"
    error_message = "valid non-default inputs must be accepted."
  }
}
