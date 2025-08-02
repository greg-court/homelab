locals {
  clusters = keys(var.clusters)
}

# 1) Load each cluster’s talosconfig
data "talos_client_configuration" "cc" {
  for_each    = local.clusters
  config_path = "${path.module}/talos_config/${each.key}/talosconfig"
}

# 2) Extract the secrets section from controlplane.yaml
data "yaml_decode" "secrets" {
  for_each = local.clusters
  content  = file("${path.module}/talos_config/${each.key}/controlplane.yaml")
}

resource "talos_machine_secrets" "imported" {
  for_each = local.clusters
  yaml     = yamlencode(data.yaml_decode.secrets[each.key].cluster.secrets)
}

# 3) Bootstrap exactly one node per cluster
resource "talos_machine_bootstrap" "this" {
  for_each             = local.clusters
  node                 = "https://${lower(element(sort(keys(each.value.hosts)), 0))}.internal:50000"
  client_configuration = data.talos_client_configuration.cc[each.key].id
  secrets              = talos_machine_secrets.imported[each.key].id
  depends_on           = [module.proxmox_vms] # wait for VMs first
}

# 4) Optionally block until the API says “healthy”
data "talos_cluster_health" "ready" {
  for_each             = local.clusters
  client_configuration = data.talos_client_configuration.cc[each.key].id
  depends_on           = [talos_machine_bootstrap.this]
}
