output "id" {
  description = "ID of the key vault."
  value       = azurerm_key_vault.this.id
}

output "name" {
  description = "Name of the key vault."
  value       = azurerm_key_vault.this.name
}

output "vault_uri" {
  description = "URI of the key vault, used for data-plane requests."
  value       = azurerm_key_vault.this.vault_uri
}

output "role_assignment_ids" {
  description = "Map of role_assignments key to the ID of the role assignment."
  value       = { for k, a in azurerm_role_assignment.this : k => a.id }
}
