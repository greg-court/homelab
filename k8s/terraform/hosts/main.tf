locals {
  all_nodes = merge([
    for cname, c in var.clusters :
    {
      for n, v in c.nodes :
      n => merge(v, {
        cluster  = cname
        vlan_id  = c.vlan_id
      })
    }
  ]...)
}

resource "proxmox_virtual_environment_vm" "node" {
  for_each = local.all_nodes

  name      = each.key
  node_name = each.value.host

  # --- CPU & RAM -----------------------------------------------------------
  cpu {
    cores = 2
  }
  memory {
    dedicated = 4096
  }

  # --- Boot & metadata -----------------------------------------------------
  on_boot = true
  tags    = ["talos"]

  # --- Network -------------------------------------------------------------
  network_device {
    bridge      = "vmbr0"
    model       = "virtio"
    mac_address = each.value.mac
    vlan_id     = each.value.vlan_id
  }

  # --- Disk ----------------------------------------------------------------
  disk {
    datastore_id = "local-lvm"
    size         = 32
    interface    = "scsi0"
  }

  # Talos will push its NoCloud config later; all we need is an ISO drive
  cdrom {
    file_id = "remote-hdd:iso/talos-nocloud-amd64-qemu.iso"
  }
}