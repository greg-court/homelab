###############################################################################
#  ⬇  identical block for each cluster – trust & dmz – parametrised by locals #
###############################################################################
locals {
  clusters_meta = {
    cluster-trust = {
      nodes_local   = local.trust_nodes
      endpoint_host = "k8s-svc-01.internal"
      out_dir       = "${path.module}/talos_config/cluster-trust"
    }
    cluster-dmz = {
      nodes_local   = local.dmz_nodes
      endpoint_host = "k8s-dmz-01.internal"
      out_dir       = "${path.module}/talos_config/cluster-dmz"
    }
  }
}

# Loop the Talos bits once per cluster
# (and let the module keep generating the cloud-init snippets)
#
# If you ever add a workers.yaml, just switch type -> "worker"
#
resource "talos_machine_secrets" "cluster" {
  for_each = local.clusters_meta
}

data "talos_client_configuration" "cluster" {
  for_each             = local.clusters_meta
  cluster_name         = each.key
  client_configuration = talos_machine_secrets.cluster[each.key].client_configuration
  nodes                = [for n in keys(each.value.nodes_local) : "${n}.internal"]
}

data "talos_machine_configuration" "cp" {
  for_each         = { for k, meta in local.clusters_meta : k => meta.nodes_local }
  cluster_name     = each.key
  machine_type     = "controlplane"
  cluster_endpoint = "https://${local.clusters_meta[each.key].endpoint_host}:6443"
  machine_secrets  = talos_machine_secrets.cluster[each.key].machine_secrets
}

# write talosconfig per-cluster so you don’t have to run talosctl gen config
resource "local_sensitive_file" "talosconfig" {
  for_each = local.clusters_meta

  filename = "${each.value.out_dir}/talosconfig"
  content = yamlencode({
    context = each.key
    contexts = {
      "${each.key}" = {
        endpoints = data.talos_client_configuration.cluster[each.key].nodes
        ca        = talos_machine_secrets.cluster[each.key].client_configuration.ca_certificate
        crt       = talos_machine_secrets.cluster[each.key].client_configuration.client_certificate
        key       = talos_machine_secrets.cluster[each.key].client_configuration.client_key
      }
    }
  })
}
