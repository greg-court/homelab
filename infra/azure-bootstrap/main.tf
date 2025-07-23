resource "azurerm_resource_group" "main" {
  name     = "rg-homelab-uks"
  location = "uksouth"
}

resource "azurerm_key_vault" "homelab" {
  name                        = "kv-homelab-uks"
  location                    = azurerm_resource_group.main.location
  resource_group_name         = azurerm_resource_group.main.name
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  sku_name                    = "standard"
  enable_rbac_authorization   = true
}

resource "azurerm_storage_account" "homelab" {
  name                     = "sthomelabuks"
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_container" "tfstate" {
  name                  = "tfstate"
  storage_account_id    = azurerm_storage_account.homelab.id
}

resource "azuread_application" "gh_homelab" {
  display_name = "gh-homelab"
}