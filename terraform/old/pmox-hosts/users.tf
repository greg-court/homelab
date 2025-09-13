resource "random_password" "pw" {
  for_each = { for uid, cfg in var.proxmox_users : uid => cfg
  if try(cfg.password, null) == null }

  length  = 32
  special = true
}

resource "proxmox_virtual_environment_user" "user" {
  for_each = var.proxmox_users

  user_id = each.key
  comment = lookup(each.value, "comment", "Managed by Terraform")
  enabled = lookup(each.value, "enabled", true)

  password = coalesce(
    lookup(each.value, "password", null),
    random_password.pw[each.key].result
  )

  dynamic "acl" {
    for_each = lookup(each.value, "acls", [])
    content {
      path      = acl.value.path
      role_id   = acl.value.role_id
      propagate = lookup(acl.value, "propagate", true)
    }
  }

  lifecycle {
    ignore_changes = [password] # keep plans clean
  }
}

locals {
  # Flatten user→tokens  into  "<user_id>!<token_name>" keys
  tokens = merge([
    for uid, cfg in var.proxmox_users :
    {
      for tname, tcfg in lookup(cfg, "tokens", {}) :
      "${uid}!${tname}" => merge(tcfg, {
        user_id    = uid
        token_name = tname
      })
    }
  ]...)
}

resource "proxmox_virtual_environment_user_token" "token" {
  for_each = local.tokens

  user_id               = each.value.user_id
  token_name            = each.value.token_name
  comment               = lookup(each.value, "comment", "Terraform-managed token")
  privileges_separation = lookup(each.value, "privileges_separation", false)
  expiration_date       = lookup(each.value, "expiration_date", null)
}

output "proxmox_token_secrets" {
  description = "Map of token identifier → secret"
  value = {
    for k, v in proxmox_virtual_environment_user_token.token :
    k => v.value
  }
  sensitive = true
}
# terraform output -json proxmox_token_secrets | jq

output "proxmox_users" {
  value = keys(proxmox_virtual_environment_user.user)
}
