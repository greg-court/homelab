resource "azuread_application" "eso_trust" {
  display_name = "k8s-eso-trust"
  owners       = [data.azurerm_client_config.current.object_id]
}

# v3.x → use client_id
resource "azuread_service_principal" "eso_trust" {
  client_id = azuread_application.eso_trust.client_id
}

# v3.x → use application_object_id
resource "azuread_application_password" "eso_pwd" {
  application_id = azuread_application.eso_trust.id
  display_name   = "k8s-eso-trust-pw"
}

# Allow the SP to read secrets in the Key Vault
resource "azurerm_role_assignment" "eso_kv" {
  scope                = azurerm_key_vault.homelab.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azuread_service_principal.eso_trust.object_id
}

# Handy outputs (copy them; never commit secrets)
output "eso_client_id" { value = azuread_application.eso_trust.client_id }
output "tenant_id" { value = data.azurerm_client_config.current.tenant_id }
output "kv_uri" { value = azurerm_key_vault.homelab.vault_uri }
output "eso_client_secret" {
  value     = azuread_application_password.eso_pwd.value
  sensitive = true
}