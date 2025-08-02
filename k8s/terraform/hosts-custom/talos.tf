############################################################
# 0.  Flatten hosts for easier looping
############################################################
locals {
  hosts = {
    for cluster_name, c in var.clusters :
    # => map key:   "cluster-name/host-id"
    # => map value: object with host + cluster data
    for host_id, h in c.hosts :
    "${cluster_name}/${host_id}" => merge(h, {
      cluster_name = cluster_name
      vlan_id      = c.vlan_id
      zone         = c.zone
    })
  }
}

############################################################
# 1.  One secrets bundle per cluster (unchanged)
############################################################
resource "talos_machine_secrets" "cluster" {
  for_each = var.clusters
}

############################################################
# 2.  One machine-config per VM, plus patch
############################################################
data "talos_machine_configuration" "vm" {
  for_each         = local.hosts

  cluster_name     = each.value.cluster_name
  machine_type     = "controlplane"                    # or "worker"
  cluster_endpoint = "https://${lower(each.key)}.internal:6443"
  machine_secrets  = talos_machine_secrets.cluster[each.value.cluster_name].machine_secrets

  # ---- host-specific bits baked right in ----
  hostname         = lower("${each.key}.internal")
  install_disk     = "/dev/sda"                        # example
  config_patches = [
    yamldecode(                                     # former patch_data block
      yamlencode({
        machine = {
          network = { hostname = lower("${each.key}.internal") }
          nodeLabels = { zone = each.value.zone }
        }
        cluster = { allowSchedulingOnControlPlanes = true }
      })
    )
  ]
}

############################################################
# 3.  Upload ONE snippet per VM
############################################################
resource "proxmox_virtual_environment_file" "vm_snippet" {
  for_each     = data.talos_machine_configuration.vm
  content_type = "snippets"
  datastore_id = "nfs-hdd"
  node_name    = each.value.node_name   # you already know the PVE node

  source_raw {
    file_name = "${lower(replace(each.key, "/", "-"))}-talos.yaml"
    data      = each.value.machine_configuration
  }
}

############################################################
# 4.  VM module keeps using `user_data_file_id`
#     (pointing at proxmox_virtual_environment_file.vm_snippet[id])
############################################################
