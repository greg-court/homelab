# Load talosconfig per cluster
data "talos_client_configuration" "cc" {
  for_each    = var.clusters
  config_path = "${path.module}/talos_config/${each.key}/talosconfig"
}

# Decode secrets from controlplane.yaml with built-in fn
locals {
  secrets_yaml = {
    for name in keys(var.clusters) :
    name => yamldecode(
      file("${path.module}/talos_config/${name}/controlplane.yaml")
    ).cluster.secrets
  }
}

resource "talos_machine_secrets" "imported" {
  for_each = local.secrets_yaml
  yaml     = yamlencode(each.value)
}

# Bootstrap first control-plane node (sorted for determinism)
resource "talos_machine_bootstrap" "this" {
  for_each = var.clusters

  node = "https://${lower(
    element(sort(keys(each.value.hosts)), 0)
  )}.internal:50000"

  client_configuration = data.talos_client_configuration.cc[each.key].id
  secrets              = talos_machine_secrets.imported[each.key].id

  depends_on = [module.proxmox_vms]
}

# Wait until the cluster is healthy
data "talos_cluster_health" "ready" {
  for_each             = var.clusters
  client_configuration = data.talos_client_configuration.cc[each.key].id
  depends_on           = [talos_machine_bootstrap.this]
}
