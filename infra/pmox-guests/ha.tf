###############################################################################
# HA GROUP  (== which nodes are allowed to run the service)
###############################################################################
resource "proxmox_virtual_environment_hagroup" "dns_ha" {
  group   = "dns-ha"
  comment = "AdGuard DNS HA group"

  nodes = {
    pve02 = 100 # primary
    pve01 = 80  # equal fallback priority
    pve03 = 60  # equal fallback priority
  }

  restricted  = true  # only these nodes may run the service
  no_failback = false # after pve02 comes back, migrate CT automatically
}


###############################################################################
# TELL THE HA MANAGER TO WATCH THAT CT
###############################################################################
resource "proxmox_virtual_environment_haresource" "adguard" {
  resource_id = "ct:${module.lxcs.ids["ADGUARD-DNS"]}"
  group       = proxmox_virtual_environment_hagroup.dns_ha.group

  state = "started" # ensure it is running; it will be migrated on failure

  # optional tunables
  max_relocate = 3 # max → hard-fail if it bounces too often
  max_restart  = 3 # restarts on the same node before relocation
}