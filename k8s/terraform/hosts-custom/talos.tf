
# 0.  Flatten clusters → hosts (and add host_id once)
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

# 1.  Secrets per cluster
resource "talos_machine_secrets" "cluster" {
  for_each = var.clusters
}

# 2.  One machine-config per VM (control-plane shown)
data "talos_machine_configuration" "vm" {
  for_each         = local.hosts

  cluster_name     = each.value.cluster_name
  machine_type     = "controlplane"
  cluster_endpoint = "https://${lower(each.value.host_id)}.internal:6443"
  machine_secrets  = talos_machine_secrets.cluster[each.value.cluster_name].machine_secrets

  # All per-node tweaks go here
  config_patches = [
    yamlencode({
      machine = {
        network = { hostname = lower("${each.value.host_id}.internal") }
        install = {
         disk = "/dev/sda"
         image = var.install_image
        }
        nodeLabels = { zone = each.value.zone }
      }
      cluster = { allowSchedulingOnControlPlanes = true }
    })
  ]
}

# 3.  Upload **one** snippet per VM
resource "proxmox_virtual_environment_file" "vm_snippet" {
  for_each     = data.talos_machine_configuration.vm
  content_type = "snippets"
  datastore_id = "nfs-hdd"
  node_name    = local.hosts[each.key].node_name

  source_raw {
    file_name = "${lower(replace(each.key, "/", "-"))}-talos.yaml"
    data      = each.value.machine_configuration
  }
}

# One client-config per cluster (re-use secrets bundle)
data "talos_client_configuration" "cc" {
  for_each            = var.clusters
  cluster_name        = each.key
  client_configuration = talos_machine_secrets.cluster[each.key].client_configuration
  nodes               = [lower(element(keys(each.value.hosts), 0))]   # first host
}

resource "local_file" "talosconfig_out" {
  for_each = data.talos_client_configuration.cc
  content  = each.value.talos_config
  filename = "${path.module}/configs/${each.key}/talosconfig"
}

# Bootstrap the first CP node after VMs exist
resource "talos_machine_bootstrap" "cluster" {
  for_each            = var.clusters
  node                = "${lower(element(keys(each.value.hosts), 0))}.internal"
  client_configuration = talos_machine_secrets.cluster[each.key].client_configuration
  depends_on          = [module.proxmox_vms]
}

# Grab kubeconfig as soon as the API comes up
resource "talos_cluster_kubeconfig" "kc" {
  for_each            = var.clusters
  node                = talos_machine_bootstrap.cluster[each.key].node
  client_configuration = talos_machine_secrets.cluster[each.key].client_configuration
  depends_on          = [talos_machine_bootstrap.cluster]
}

resource "local_file" "kubeconfig_out" {
  for_each = talos_cluster_kubeconfig.kc
  content  = each.value.kubeconfig_raw
  filename = "${path.module}/configs/${each.key}/kubeconfig"
}
