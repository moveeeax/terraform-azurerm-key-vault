# Changelog

All notable changes to this module are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the project uses
[Semantic Versioning](https://semver.org/).

## [Unreleased]

### Added

- `role_assignments` input creating `azurerm_role_assignment` resources scoped
  to the vault, keyed by static names. `role_definition_name` must be a
  `Key Vault ...` role, so the input cannot grant Owner, Contributor or other
  general roles on the vault; `principal_id` must be a GUID; `principal_type`
  is optional (User, Group or ServicePrincipal). A precondition rejects
  assignments while `enable_rbac_authorization = false`. New
  `role_assignment_ids` output. Defaults to `{}`, so existing vaults plan
  unchanged.

## [1.1.0] - 2026-11-05

### Changed

- Set `rbac_authorization_enabled` instead of `enable_rbac_authorization`,
  which azurerm 5.0 removed. azurerm is now bound to `>= 4.42.0, < 6.0` (the
  first release with the new argument); CI validates and tests that floor. The
  module input keeps its name, `enable_rbac_authorization`.
- CI: bump actions to their current majors, pin tool versions, restrict the
  workflow token to `contents: read`, add Dependabot.
- Docs: pin the README usage `source` to a release tag; fix the LICENSE year.

## [1.0.0] - 2026-07-26

Initial release with purge protection on, 90-day soft delete, a `Deny` network
ACL and RBAC authorization by default (`v0.1.0` points at the same commit).

[Unreleased]: https://github.com/moveeeax/terraform-azurerm-key-vault/compare/v1.1.0...HEAD
[1.1.0]: https://github.com/moveeeax/terraform-azurerm-key-vault/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/moveeeax/terraform-azurerm-key-vault/releases/tag/v1.0.0
