terraform {
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = ">= 5.0"
    }
  }
}

data "cloudflare_zones" "this" {
  name   = var.zone_name
  status = "active"
}

locals {
  zone_id = one(data.cloudflare_zones.this.result).id

  recs = {
    for r in var.records :
    "${r.name}_${r.type}" => merge(r, {
      zone_id = local.zone_id
    })
  }
}

resource "cloudflare_dns_record" "this" {
  for_each = local.recs

  zone_id  = each.value.zone_id
  name     = each.value.name
  type     = each.value.type
  content  = each.value.content
  ttl      = each.value.ttl
  proxied  = try(each.value.proxied, null)
  priority = try(each.value.priority, null)

  lifecycle {
    ignore_changes = [
      ttl,
    ]
  }
}