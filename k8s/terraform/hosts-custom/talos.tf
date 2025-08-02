############################################################
# 0.  Flatten clusters → hosts (and add host_id once)
############################################################
locals {
  hosts = merge([
    for cluster_name, c in var.clusters : {
      for host_id, h in c.hosts :
      "${cluster_name}/${host_id}" => merge(h, {
        cluster_name = cluster_name
        host_id      = host_id
        vlan_id      = c.vlan_id
        zone         = c.zone
      })
    }
  ]...)
}

############################################################
# 1.  Secrets per cluster
############################################################
resource "talos_machine_secrets" "cluster" {
  for_each = var.clusters
}

############################################################
# 2.  One machine-config per VM (control-plane shown)
############################################################
data "talos_machine_configuration" "vm" {
  for_each         = local.hosts

  cluster_name     = each.value.cluster_name
  machine_type     = "controlplane"
  cluster_endpoint = "https://${lower(each.value.host_id)}.internal:6443"
  machine_secrets  = talos_machine_secrets.cluster[each.value.cluster_name].machine_secrets

  hostname         = lower("${each.value.host_id}.internal")
  install_disk     = "/dev/sda"

  config_patches = [
    yamlencode({
      machine = {
        network    = { hostname = lower("${each.value.host_id}.internal") }
        nodeLabels = { zone = each.value.zone }
      }
      cluster = { allowSchedulingOnControlPlanes = true }
    })
  ]
}

############################################################
# 3.  Upload **one** snippet per VM
############################################################
resource "proxmox_virtual_environment_file" "vm_snippet" {
  for_each     = data.talos_machine_configuration.vm
  content_type = "snippets"
  datastore_id = "nfs-hdd"
  node_name    = each.value.node_name

  source_raw {
    file_name = "${lower(replace(each.key, "/", "-"))}-talos.yaml"
    data      = each.value.machine_configuration
  }
}
