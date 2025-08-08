# variable "trust_cluster_oidc_issuer_url" {
#   description = "OIDC issuer URL for the TRUST cluster"
#   type        = string
# }

locals {
  ad_apps = {
    gh-homelab = {
      federated_identities = {
        gh-actions-main = {
          issuer    = "https://token.actions.githubusercontent.com"
          subject   = "repo:greg-court/homelab:ref:refs/heads/main"
          audiences = ["api://AzureADTokenExchange"]

          role_assignments = [
            { role = "Key Vault Secrets User", scope = azurerm_key_vault.homelab.id },
            { role = "Storage Blob Data Contributor", scope = azurerm_storage_account.homelab.id },
          ]
        }
      }
    }
    # k8s-eso-trust = {
    #   federated_identities = {
    #     eso-trust = {
    #       issuer    = var.trust_cluster_oidc_issuer_url
    #       subject   = "system:serviceaccount:external-secrets:external-secrets"
    #       audiences = ["api://AzureADTokenExchange"]

    #       role_assignments = [
    #         { role = "Key Vault Secrets User", scope = azurerm_key_vault.homelab.id },
    #       ]
    #     }
    #   }
    # }
  }
}

# 2.  Applications & Service Principals
resource "azuread_application" "app" {
  for_each     = local.ad_apps
  display_name = each.key
}

resource "azuread_service_principal" "sp" {
  for_each  = azuread_application.app
  client_id = each.value.client_id
}

# 3.  Federated identity credentials (flattened)
locals {
  federated_flat = flatten([
    for app_key, app_def in local.ad_apps : [
      for fid_key, fid_def in app_def.federated_identities : merge(
        fid_def,
        {
          map_key        = "${app_key}-${fid_key}" # ⚑ used only for for_each
          display_name   = fid_key                 # ⚑ what you want to see in Entra ID
          application_id = azuread_application.app[app_key].id
          principal_id   = azuread_service_principal.sp[app_key].object_id
        }
      )
    ]
  ])
}

resource "azuread_application_federated_identity_credential" "fic" {
  for_each = { for f in local.federated_flat : f.map_key => f }

  application_id = each.value.application_id
  display_name   = each.value.display_name # ← now just “gh-actions-main”
  description    = try(each.value.description, null)
  issuer         = each.value.issuer
  subject        = each.value.subject
  audiences      = each.value.audiences
}


# 4.  Role assignments (flattened again)
locals {
  role_flat = flatten([
    for f in local.federated_flat : [
      for ra in f.role_assignments : {
        key          = "${f.map_key}-${ra.role}-${md5(ra.scope)}"
        principal_id = f.principal_id
        scope        = ra.scope
        role_name    = ra.role
      }
    ]
  ])
}

resource "azurerm_role_assignment" "ra" {
  for_each = { for r in local.role_flat : r.key => r }

  scope                = each.value.scope
  role_definition_name = each.value.role_name
  principal_id         = each.value.principal_id
}
