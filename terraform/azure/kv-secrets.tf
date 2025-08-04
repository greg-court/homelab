variable "secret_names" {}
resource "azurerm_key_vault_secret" "kv_secrets" {
  for_each = var.secret_names

  name         = each.key
  value        = each.value
  key_vault_id = azurerm_key_vault.homelab.id

  lifecycle {
    ignore_changes = [value]
  }
}
