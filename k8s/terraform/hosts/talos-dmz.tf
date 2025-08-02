resource "talos_machine_secrets" "dmz" {}

data "talos_client_configuration" "dmz" {
  cluster_name         = "cluster-dmz"
  client_configuration = talos_machine_secrets.dmz.client_configuration
  nodes                = [for hostname, _ in var.clusters.dmz.nodes : "${hostname}.internal"]
}

data "talos_machine_configuration" "dmz_cp" {
  for_each         = var.clusters.dmz.nodes
  cluster_name     = "cluster-dmz"
  machine_type     = "controlplane"
  cluster_endpoint = var.clusters.dmz.endpoint
  machine_secrets  = talos_machine_secrets.dmz.machine_secrets
}

resource "talos_machine_configuration_apply" "dmz_cp" {
  for_each                    = data.talos_machine_configuration.dmz_cp
  client_configuration        = talos_machine_secrets.dmz.client_configuration
  machine_configuration_input = each.value.machine_configuration
  node                        = "${each.key}.internal"

  config_patches = [
    yamlencode({
      machine = {
        install = {
          disk  = var.disk_device
          image = var.talos_install_image
          auto  = true
        }
        network    = { hostname = each.key }
        nodeLabels = { zone = "dmz" }
      }
      cluster = { allowSchedulingOnControlPlanes = true }
    })
  ]
}

resource "talos_machine_bootstrap" "dmz" {
  depends_on           = [talos_machine_configuration_apply.dmz_cp]
  node                 = "k8s-dmz-01.internal"
  client_configuration = talos_machine_secrets.dmz.client_configuration
}

resource "talos_cluster_kubeconfig" "dmz" {
  depends_on           = [talos_machine_bootstrap.dmz]
  client_configuration = talos_machine_secrets.dmz.client_configuration
  node                 = "k8s-dmz-01.internal"
}

resource "local_sensitive_file" "dmz_kubeconfig" {
  filename = "${path.module}/cluster-dmz/kubeconfig"
  content  = talos_cluster_kubeconfig.dmz.kubeconfig_raw
}

resource "local_sensitive_file" "dmz_talosconfig" {
  filename = "${path.module}/cluster-dmz/talosconfig"
  content  = yamlencode(talos_machine_secrets.dmz.client_configuration)
}
