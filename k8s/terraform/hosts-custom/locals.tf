locals {
  global_common = {
    tags             = ["talos"]
    on_boot          = true
    agent            = true
    bios             = "seabios"
    cpu              = { cores = 2 }
    memory           = { dedicated = 4096 }
    operating_system = { type = "l26" }
    disks            = { "scsi0" = { size = 16 } }
    cdrom            = { file_id = "nfs-hdd:iso/talos-nocloud-amd64-qemu.iso" }
  }

  # ­───────────────── flatten ──────────────────
  all_vms = merge([
    for cname, c in var.clusters : {
      for hostname, n in c.nodes :
      hostname => merge(
        local.global_common,
        lookup(c, "node_defaults", {}),
        {
          network_devices = [{
            vlan_id     = c.vlan_id
            mac_address = n.mac
          }]

          talos = {
            cluster = "cluster-${cname}"
            type    = "controlplane"
            patch_data = yamlencode({
              machine = {
                network    = { hostname = "${hostname}.internal" }
                nodeLabels = { zone = cname }
              }
            })
          }

          node_name = n.pve_host
        }
      )
    }
  ]...)

  trust_nodes = { for k, v in local.all_vms : k => v if v.talos.cluster == "cluster-trust" }
  dmz_nodes   = { for k, v in local.all_vms : k => v if v.talos.cluster == "cluster-dmz" }
}
