resource "azurerm_resource_group" "main" {
  name     = "rg-homelab-uks"
  location = "uksouth"
}

resource "azurerm_key_vault" "homelab" {
  name                      = "kv-homelab-uks"
  location                  = azurerm_resource_group.main.location
  resource_group_name       = azurerm_resource_group.main.name
  tenant_id                 = data.azurerm_client_config.current.tenant_id
  sku_name                  = "standard"
  enable_rbac_authorization = true
}

resource "azurerm_storage_account" "homelab" {
  name                     = "sthomelabuks"
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_container" "tfstate" {
  name               = "tfstate"
  storage_account_id = azurerm_storage_account.homelab.id
}

resource "azuread_application" "gh_homelab" {
  display_name = "gh-homelab"
}

resource "azuread_application_federated_identity_credential" "gh_homelab_oidc" {
  application_id = azuread_application.gh_homelab.id

  display_name = "gh-actions-main"
  description  = "OIDC federated credential for GitHub Actions (main branch)"

  issuer    = "https://token.actions.githubusercontent.com"
  subject   = "repo:greg-court/homelab:ref:refs/heads/main"
  audiences = ["api://AzureADTokenExchange"]
}

resource "azuread_service_principal" "gh_homelab" {
  client_id = azuread_application.gh_homelab.client_id
}

resource "azurerm_role_assignment" "kv_secrets_user" {
  scope                = azurerm_key_vault.homelab.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azuread_service_principal.gh_homelab.object_id
}

resource "azurerm_role_assignment" "storage_blob_contributor" {
  scope                = azurerm_storage_account.homelab.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azuread_service_principal.gh_homelab.object_id
}