# terraform-azurerm-key-vault

Terraform module that manages an [Azure](https://azure.microsoft.com/) Key
Vault. It defaults to RBAC-based data-plane authorization, purge protection on,
a 90-day soft-delete window and a `Deny` network ACL, resolves the tenant ID
from the current client when not supplied, and exposes the vault URI for
downstream secret, key and certificate resources.

## Defaults worth knowing about

| Default | Why |
|---------|-----|
| `purge_protection_enabled = true` | Without purge protection a soft-deleted vault, and every key, secret and certificate in it, can be purged permanently. Anything encrypted with a customer-managed key from that vault becomes unrecoverable. **Azure does not allow purge protection to be turned off again once it has been enabled on a vault.** |
| `soft_delete_retention_days = 90` | The Azure maximum, so a mistaken delete has the longest possible recovery window. Note that with purge protection on, a destroyed vault name stays reserved for the whole retention period. |
| `network_acls_default_action = "Deny"` | `Allow` accepts data-plane traffic from any source address. Grant access explicitly with `network_acls_ip_rules` and `network_acls_virtual_network_subnet_ids`. |
| `enable_rbac_authorization = true` | Azure RBAC rather than legacy vault access policies. This module intentionally manages no `access_policy` blocks; if you set this to `false`, attach `azurerm_key_vault_access_policy` resources yourself. |

`public_network_access_enabled` still defaults to `true`, because turning it off
requires a private endpoint that this module does not create. The `Deny`
network ACL is what gates access on the public endpoint. Set it to `false` once
you have private connectivity in place.

This module manages the vault only. It deliberately takes no secret, key or
certificate **values** as inputs, so there is no input that could end up in
state or in a plan by way of this module.

## Usage

```hcl
module "key_vault" {
  source = "github.com/moveeeax/terraform-azurerm-key-vault?ref=v1.0.0"

  name                = "prod-kv-01"
  resource_group_name = "prod-rg"
  location            = "eastus"

  sku_name = "standard"

  # Required, because the default network ACL action is Deny.
  network_acls_ip_rules = ["203.0.113.0/24"]

  tags = {
    Environment = "production"
    ManagedBy   = "terraform"
  }
}
```

A runnable example lives in [`examples/basic`](examples/basic).

## Requirements

| Name      | Version           |
|-----------|-------------------|
| terraform | >= 1.5            |
| azurerm   | >= 4.42.0, < 6.0  |

azurerm 5.0 removed `enable_rbac_authorization` from `azurerm_key_vault` and
made its replacement, `rbac_authorization_enabled`, required. The module sets
`rbac_authorization_enabled`, which first appeared in azurerm 4.42.0, so that
is the floor (v1 of this module supported 3.19 and later). CI validates and
tests the module against 4.42.0 and the latest 5.x release; 6.x is excluded
until it has been tested. The module input keeps its name,
`enable_rbac_authorization`.

## Inputs

| Name                                      | Description                                                                | Type          | Default            | Required |
|-------------------------------------------|----------------------------------------------------------------------------|---------------|--------------------|:--------:|
| `name`                                    | Name of the key vault. Globally unique, 3-24 alphanumerics and hyphens.    | `string`      | n/a                |   yes    |
| `resource_group_name`                     | Name of the resource group in which to create the key vault.               | `string`      | n/a                |   yes    |
| `location`                                | Azure region in which to create the key vault.                             | `string`      | n/a                |   yes    |
| `tenant_id`                               | Azure AD tenant ID. Null uses the current client's tenant.                 | `string`      | `null`             |    no    |
| `sku_name`                                | SKU of the key vault. Either standard or premium.                          | `string`      | `"standard"`       |    no    |
| `enabled_for_disk_encryption`             | Whether Azure Disk Encryption can retrieve secrets and unwrap keys.        | `bool`        | `false`            |    no    |
| `purge_protection_enabled`                | Whether purge protection is enabled. Cannot be turned off once enabled.    | `bool`        | `true`             |    no    |
| `soft_delete_retention_days`              | Days soft-deleted vault items are retained, between 7 and 90.              | `number`      | `90`               |    no    |
| `public_network_access_enabled`           | Whether the vault endpoint is reachable over the public internet.          | `bool`        | `true`             |    no    |
| `enable_rbac_authorization`               | Whether to use Azure RBAC instead of vault access policies.                | `bool`        | `true`             |    no    |
| `network_acls_bypass`                     | Which traffic bypasses the network ACLs. Either AzureServices or None.     | `string`      | `"AzureServices"`  |    no    |
| `network_acls_default_action`             | Default action when no network ACL rule matches. Either Allow or Deny.     | `string`      | `"Deny"`           |    no    |
| `network_acls_ip_rules`                   | IPv4 addresses or CIDR ranges allowed to reach the vault.                  | `list(string)`| `[]`               |    no    |
| `network_acls_virtual_network_subnet_ids` | Subnet IDs allowed to reach the vault.                                     | `list(string)`| `[]`               |    no    |
| `tags`                                    | Map of tags applied to the key vault.                                      | `map(string)` | `{}`               |    no    |

## Outputs

| Name        | Description                                    |
|-------------|------------------------------------------------|
| `id`        | ID of the key vault.                           |
| `name`      | Name of the key vault.                          |
| `vault_uri` | URI of the key vault, used for data-plane requests.|

## Tests

```
terraform test
```

The suite in [`tests/`](tests) uses `mock_provider`, so it needs no Azure
credentials and no network access to Azure. It pins the safe defaults above and
checks every input validation rule. `mock_provider` requires Terraform (or
OpenTofu) >= 1.7; that is a requirement of the test suite only, not of the
module.

## License

[MIT](LICENSE)
