variable "name" {
  description = "Name of the key vault. Must be globally unique, 3-24 alphanumeric characters."
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group in which to create the key vault."
  type        = string
}

variable "location" {
  description = "Azure region in which to create the key vault."
  type        = string
}

variable "tenant_id" {
  description = "Azure AD tenant ID used for authenticating requests. Null uses the current client's tenant."
  type        = string
  default     = null
}

variable "sku_name" {
  description = "SKU of the key vault. Either standard or premium."
  type        = string
  default     = "standard"
}

variable "enabled_for_disk_encryption" {
  description = "Whether Azure Disk Encryption can retrieve secrets and unwrap keys from the vault."
  type        = bool
  default     = false
}

variable "purge_protection_enabled" {
  description = "Whether purge protection is enabled, preventing permanent deletion during the retention period."
  type        = bool
  default     = false
}

variable "soft_delete_retention_days" {
  description = "Number of days soft-deleted vault items are retained, between 7 and 90."
  type        = number
  default     = 90
}

variable "public_network_access_enabled" {
  description = "Whether the key vault is reachable over the public internet."
  type        = bool
  default     = true
}

variable "enable_rbac_authorization" {
  description = "Whether to use Azure RBAC instead of vault access policies for data-plane authorization."
  type        = bool
  default     = true
}

variable "network_acls_bypass" {
  description = "Which traffic bypasses the network ACLs. Either AzureServices or None."
  type        = string
  default     = "AzureServices"
}

variable "network_acls_default_action" {
  description = "Default action when no network ACL rule matches. Either Allow or Deny."
  type        = string
  default     = "Allow"
}

variable "tags" {
  description = "Map of tags applied to the key vault."
  type        = map(string)
  default     = {}
}
