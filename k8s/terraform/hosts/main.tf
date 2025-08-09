locals {
  base_vm = {
    tags             = ["talos"]
    on_boot          = true
    agent            = true
    bios             = "seabios"
    memory           = { dedicated = 4096 }
    operating_system = { type = "l26" }
    disks            = { "scsi0" = { size = 16 } }
    cdrom            = { file_id = "nfs-hdd:iso/talos-nocloud-amd64-qemu.iso" }
  }
}

locals {
  vms = merge([
    for cluster_name, c in var.clusters : {
      for host_id, h in c.hosts :
      upper(host_id) => merge(
        local.base_vm,
        {
          tags            = distinct(concat(local.base_vm.tags, lookup(c, "extra_tags", [])))
          network_devices = [{ vlan_id = c.vlan_id, mac_address = h.mac_address }]
          node_name       = h.node_name
          cpu             = h.cpu
          disks           = merge(local.base_vm.disks, lookup(h, "disks", {}))
          initialization = {
            datastore_id      = "local-zfs"
            user_data_file_id = proxmox_virtual_environment_file.vm_snippet["${cluster_name}/${host_id}"].id
          }
        }
      )
    }
  ]...)
}

module "proxmox_vms" {
  source = "../../../tf-modules/proxmox-vms"
  vms    = local.vms
}