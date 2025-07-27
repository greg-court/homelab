locals {
  # Order of nodes in your cluster (edit if you add/remove nodes)
  cluster_nodes = ["pve01", "pve02", "pve03"]

  # List of CT names to put under HA. By default: every CT in var.lxcs
  ha_cts = {
    for name, cfg in var.lxcs :
    name => cfg
    if true  # flip to a conditional if you want to filter
  }

  # Priority used for non‑primary nodes
  fallback_priority = 80

  # Build a priority map for each CT based on its current node_name
  priorities = {
    for name, cfg in local.ha_cts :
    name => {
      for n in local.cluster_nodes :
      n => n == cfg.node_name ? 100 : local.fallback_priority
    }
  }
}

###############################################
# HA GROUPS (which nodes can run each CT + priorities)
###############################################
resource "proxmox_virtual_environment_hagroup" "ct" {
  for_each   = local.ha_cts

  group      = "ct-${lower(each.key)}"          # eg. ct-adguard-dns
  comment    = "HA group for ${each.key}"
  nodes      = local.priorities[each.key]

  restricted  = true
  no_failback = false
}

###############################################
# HA RESOURCES (tell the HA manager to watch/move the CT)
###############################################
resource "proxmox_virtual_environment_haresource" "ct" {
  for_each    = local.ha_cts

  # module.lxcs.ids must return a map(name -> vmid). Your module already does.
  resource_id = "ct:${module.lxcs.ids[each.key]}"
  group       = proxmox_virtual_environment_hagroup.ct[each.key].group

  state        = "started"  # keep running, start it elsewhere on failure
  max_relocate = 3           # hard fail if it bounces >3 times
  max_restart  = 3           # restarts on same node before relocating
}

###############################################
# OPTIONAL: fine‑grained overrides per CT (example)
###############################################
# variable "ha_overrides" {
#   type = map(object({
#     nodes       = map(number)  # explicit node->priority map
#     no_failback = optional(bool)
#     restricted  = optional(bool)
#   }))
#   default = {}
# }
#
# locals {
#   priorities = merge(
#     {
#       for name, cfg in local.ha_cts :
#       name => {
#         for n in local.cluster_nodes :
#         n => n == cfg.node_name ? 100 : local.fallback_priority
#       }
#     },
#     { for name, o in var.ha_overrides : name => lookup(o, "nodes", {}) }
#   )
# }
#
# Then inside the resources above:
#   nodes      = local.priorities[each.key]
#   no_failback = lookup(var.ha_overrides[each.key], "no_failback", false)
#   restricted  = lookup(var.ha_overrides[each.key], "restricted", true)

###############################################
# HOW TO USE / CHECK
#   terraform apply
#   ha-manager status    # on any PVE node
#   ha-manager group list
#   ha-manager resource list
###############################################
