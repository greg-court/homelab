locals {
  base_vm = {
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
          cpu             = coalesce(try(h.cpu, null), try(c.cpu, null), local.base_vm.cpu)
          memory          = coalesce(try(h.memory, null), try(c.memory, null), local.base_vm.memory)
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
  source = "../../tf-modules/proxmox-vms"
  vms    = local.vms
}

# below modules only run on 2nd pass to ensure the kubeconfig is available
module "cluster_trust" {
  count = fileexists("${path.module}/configs/cluster-trust/kubeconfig") ? 1 : 0

  source = "./clusters/cluster-trust"
  providers = {
    kubernetes = kubernetes.trust
    helm       = helm.trust
  }

  azure_tenant_id     = var.azure_tenant_id
  azure_client_id     = var.azure_client_id
  azure_client_secret = var.azure_client_secret

  depends_on = [module.proxmox_vms]
}

module "cluster_dmz" {
  count = fileexists("${path.module}/configs/cluster-dmz/kubeconfig") ? 1 : 0

  source = "./clusters/cluster-dmz"
  providers = {
    kubernetes = kubernetes.dmz
    helm       = helm.dmz
  }

  depends_on = [module.proxmox_vms]
}