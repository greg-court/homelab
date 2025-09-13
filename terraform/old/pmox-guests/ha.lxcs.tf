locals {
  # Nodes in cluster
  cluster_nodes = ["pve01", "pve02", "pve03"]

  # CTs eligible for HA
  ha_cts = {
    for name, cfg in var.lxcs :
    name => cfg
    if try(cfg.ha_enabled, true) == true            # Exclude if ha_enabled is false
    && try(cfg.disk.datastore_id != null            # Check it's not null
    && cfg.disk.datastore_id != "local-zfs", false) # Check its not local-zfs
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
  for_each = local.ha_cts

  group   = "ct-${lower(each.key)}"
  comment = "HA group for ${each.key}"
  nodes   = local.priorities[each.key]

  restricted  = true
  no_failback = false
}

###############################################
# HA RESOURCES (tell the HA manager to watch/move the CT)
###############################################
resource "proxmox_virtual_environment_haresource" "ct" {
  for_each = local.ha_cts

  resource_id = "ct:${module.lxcs.ids[each.key]}"
  group       = proxmox_virtual_environment_hagroup.ct[each.key].group

  state        = "started" # keep running, start it elsewhere on failure
  max_relocate = 3         # hard fail if it bounces >3 times
  max_restart  = 3         # restarts on same node before relocating
}