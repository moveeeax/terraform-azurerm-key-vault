data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "this" {
  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location
  tenant_id           = coalesce(var.tenant_id, data.azurerm_client_config.current.tenant_id)
  sku_name            = var.sku_name

  enabled_for_disk_encryption   = var.enabled_for_disk_encryption
  purge_protection_enabled      = var.purge_protection_enabled
  soft_delete_retention_days    = var.soft_delete_retention_days
  public_network_access_enabled = var.public_network_access_enabled
  rbac_authorization_enabled    = var.enable_rbac_authorization

  network_acls {
    bypass                     = var.network_acls_bypass
    default_action             = var.network_acls_default_action
    ip_rules                   = var.network_acls_ip_rules
    virtual_network_subnet_ids = var.network_acls_virtual_network_subnet_ids
  }

  tags = var.tags
}

# Data-plane role assignments scoped to this vault. Key Vault data-plane roles
# only take effect when the vault uses RBAC authorization, so assignments are
# refused while enable_rbac_authorization is false.
resource "azurerm_role_assignment" "this" {
  for_each = var.role_assignments

  scope                = azurerm_key_vault.this.id
  role_definition_name = each.value.role_definition_name
  principal_id         = each.value.principal_id
  principal_type       = each.value.principal_type
  description          = each.value.description

  lifecycle {
    precondition {
      condition     = var.enable_rbac_authorization
      error_message = "role_assignments requires enable_rbac_authorization = true; Key Vault data-plane roles have no effect on a vault that uses access policies."
    }
  }
}

# Private endpoints for the vault's "vault" sub-resource. These do not change
# public_network_access_enabled; turn public access off yourself once private
# connectivity and DNS resolution work.
resource "azurerm_private_endpoint" "this" {
  for_each = var.private_endpoints

  name                = coalesce(each.value.name, "${var.name}-pe-${each.key}")
  resource_group_name = coalesce(each.value.resource_group_name, var.resource_group_name)
  location            = coalesce(each.value.location, var.location)
  subnet_id           = each.value.subnet_id

  private_service_connection {
    name                           = coalesce(each.value.name, "${var.name}-pe-${each.key}")
    private_connection_resource_id = azurerm_key_vault.this.id
    subresource_names              = ["vault"]
    is_manual_connection           = false
  }

  dynamic "private_dns_zone_group" {
    for_each = length(coalesce(each.value.private_dns_zone_ids, [])) > 0 ? [1] : []

    content {
      name                 = "default"
      private_dns_zone_ids = each.value.private_dns_zone_ids
    }
  }

  tags = var.tags
}
