locals {
   all_nodes = merge([
    for cname, c in var.clusters :
    {
      for n, v in c.nodes :
      "${cname}_${n}" => merge(v, { cluster = cname })
    }
  ]...)
}

resource "proxmox_vm_qemu" "node" {
  for_each = local.all_nodes

  name        = each.value.ip                     # VM name on Proxmox
  vmid        = each.value.vmid
  target_node = each.value.host
  cores       = 2
  memory      = 4096
  bios        = "seabios"
  agent       = 1
  onboot      = true
  tags        = "talos"

  network {
    model   = "virtio"
    bridge  = "vmbr0"
    tag     = each.value.cluster == "trust" ? local.clusters.trust.vlan_id : local.clusters.dmz.vlan_id
    macaddr = each.value.mac
  }

  disk {
    slot    = 0
    size    = "32G"
    storage = "local-lvm"
    type    = "scsi"
  }
}
