# terraform-azurerm-key-vault

Terraform module that manages an [Azure](https://azure.microsoft.com/) Key
Vault. It defaults to RBAC-based data-plane authorization with a 90-day
soft-delete window, resolves the tenant ID from the current client when not
supplied, and exposes the vault URI for downstream secret, key and certificate
resources.

## Usage

```hcl
module "key_vault" {
  source = "github.com/cybercapybara/terraform-azurerm-key-vault"

  name                = "prod-kv-01"
  resource_group_name = "prod-rg"
  location            = "eastus"

  sku_name                 = "standard"
  purge_protection_enabled = true

  tags = {
    Environment = "production"
    ManagedBy   = "terraform"
  }
}
```

A runnable example lives in [`examples/basic`](examples/basic).

## Requirements

| Name      | Version  |
|-----------|----------|
| terraform | >= 1.5   |
| azurerm   | >= 3.0   |

## Inputs

| Name                            | Description                                                                | Type          | Default            | Required |
|---------------------------------|----------------------------------------------------------------------------|---------------|--------------------|:--------:|
| `name`                          | Name of the key vault. Globally unique, 3-24 alphanumeric characters.      | `string`      | n/a                |   yes    |
| `resource_group_name`           | Name of the resource group in which to create the key vault.               | `string`      | n/a                |   yes    |
| `location`                      | Azure region in which to create the key vault.                             | `string`      | n/a                |   yes    |
| `tenant_id`                     | Azure AD tenant ID. Null uses the current client's tenant.                 | `string`      | `null`             |    no    |
| `sku_name`                      | SKU of the key vault. Either standard or premium.                          | `string`      | `"standard"`       |    no    |
| `enabled_for_disk_encryption`   | Whether Azure Disk Encryption can retrieve secrets and unwrap keys.        | `bool`        | `false`            |    no    |
| `purge_protection_enabled`      | Whether purge protection is enabled.                                       | `bool`        | `false`            |    no    |
| `soft_delete_retention_days`    | Days soft-deleted vault items are retained, between 7 and 90.              | `number`      | `90`               |    no    |
| `public_network_access_enabled` | Whether the key vault is reachable over the public internet.               | `bool`        | `true`             |    no    |
| `enable_rbac_authorization`     | Whether to use Azure RBAC instead of vault access policies.                | `bool`        | `true`             |    no    |
| `network_acls_bypass`           | Which traffic bypasses the network ACLs.                                   | `string`      | `"AzureServices"`  |    no    |
| `network_acls_default_action`   | Default action when no network ACL rule matches.                           | `string`      | `"Allow"`          |    no    |
| `tags`                          | Map of tags applied to the key vault.                                      | `map(string)` | `{}`               |    no    |

## Outputs

| Name        | Description                                    |
|-------------|------------------------------------------------|
| `id`        | ID of the key vault.                           |
| `name`      | Name of the key vault.                          |
| `vault_uri` | URI of the key vault, used for data-plane requests.|

## License

[MIT](LICENSE)
