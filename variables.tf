variable "name" {
  description = "Name of the key vault. Must be globally unique, 3-24 characters, alphanumerics and hyphens, starting with a letter and ending with a letter or digit."
  type        = string

  validation {
    condition = (
      can(regex("^[a-zA-Z][a-zA-Z0-9-]{1,22}[a-zA-Z0-9]$", var.name))
      && !can(regex("--", var.name))
    )
    error_message = "name must be 3-24 characters, contain only alphanumerics and hyphens, start with a letter, end with a letter or digit, and must not contain consecutive hyphens."
  }
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

  validation {
    condition     = contains(["standard", "premium"], var.sku_name)
    error_message = "sku_name must be either \"standard\" or \"premium\"."
  }
}

variable "enabled_for_disk_encryption" {
  description = "Whether Azure Disk Encryption can retrieve secrets and unwrap keys from the vault."
  type        = bool
  default     = false
}

variable "purge_protection_enabled" {
  description = "Whether purge protection is enabled, preventing permanent deletion of the vault and its keys, secrets and certificates during the soft-delete retention period. Defaults to true. Note that Azure does not allow purge protection to be turned off again once it has been enabled on a vault."
  type        = bool
  default     = true
}

variable "soft_delete_retention_days" {
  description = "Number of days soft-deleted vault items are retained, between 7 and 90."
  type        = number
  default     = 90

  validation {
    condition = (
      var.soft_delete_retention_days >= 7
      && var.soft_delete_retention_days <= 90
      && floor(var.soft_delete_retention_days) == var.soft_delete_retention_days
    )
    error_message = "soft_delete_retention_days must be a whole number between 7 and 90."
  }
}

variable "public_network_access_enabled" {
  description = "Whether the key vault endpoint is reachable over the public internet. Even when true, the network_acls_default_action setting still governs which callers are actually allowed through."
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

  validation {
    condition     = contains(["AzureServices", "None"], var.network_acls_bypass)
    error_message = "network_acls_bypass must be either \"AzureServices\" or \"None\"."
  }
}

variable "network_acls_default_action" {
  description = "Default action when no network ACL rule matches. Either Allow or Deny. Defaults to Deny; grant access explicitly with network_acls_ip_rules and network_acls_virtual_network_subnet_ids."
  type        = string
  default     = "Deny"

  validation {
    condition     = contains(["Allow", "Deny"], var.network_acls_default_action)
    error_message = "network_acls_default_action must be either \"Allow\" or \"Deny\"."
  }
}

variable "network_acls_ip_rules" {
  description = "Public IPv4 addresses or CIDR ranges allowed to reach the vault when network_acls_default_action is Deny."
  type        = list(string)
  default     = []
}

variable "network_acls_virtual_network_subnet_ids" {
  description = "IDs of subnets allowed to reach the vault when network_acls_default_action is Deny. The subnets need the Microsoft.KeyVault service endpoint enabled."
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Map of tags applied to the key vault."
  type        = map(string)
  default     = {}
}

variable "role_assignments" {
  description = <<-EOT
    Azure RBAC role assignments on the vault, keyed by a static name.
    role_definition_name must be a built-in Key Vault role such as
    "Key Vault Secrets User", "Key Vault Crypto User" or
    "Key Vault Administrator". principal_type (User, Group or
    ServicePrincipal) is optional; setting it avoids a replication race when
    the principal was created in the same apply. Requires
    enable_rbac_authorization = true. Empty (the default) creates no
    assignments.
  EOT
  type = map(object({
    principal_id         = string
    role_definition_name = string
    principal_type       = optional(string)
    description          = optional(string)
  }))
  default = {}

  validation {
    # Keeps the input to data-plane roles: Owner, Contributor or User Access
    # Administrator on the vault would let the principal change the vault
    # itself or hand out access, which is not what this input is for.
    condition     = alltrue([for a in values(var.role_assignments) : can(regex("^Key Vault ", a.role_definition_name))])
    error_message = "role_assignments[*].role_definition_name must be a Key Vault role, for example \"Key Vault Secrets User\"; general roles such as Owner or Contributor are rejected."
  }

  validation {
    condition     = alltrue([for a in values(var.role_assignments) : a.principal_type == null || contains(["User", "Group", "ServicePrincipal"], coalesce(a.principal_type, "User"))])
    error_message = "role_assignments[*].principal_type must be User, Group or ServicePrincipal."
  }

  validation {
    condition     = alltrue([for a in values(var.role_assignments) : can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", a.principal_id))])
    error_message = "role_assignments[*].principal_id must be an object ID (GUID)."
  }
}
