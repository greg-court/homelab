locals {
  base_patch = yamlencode({
    machine = {
      install = { disk = var.install_disk }
      features = {
        kubePrism = { enabled = true, port = 7445 }
        hostDNS   = { enabled = true, forwardKubeDNSToHost = false }
      }
    }
    cluster = {
      allowSchedulingOnControlPlanes = true
      network = { cni = { name = "none" } }
      proxy   = { disabled = true }
      apiServer = {
        extraArgs = {
          "service-account-issuer" = "https://kubernetes.default.svc"
          "api-audiences"          = "https://kubernetes.default.svc"
        }
      }
    }
  })
  tmp_dir = "${path.module}/tmp"
}

# ⬇️ fix depends_on target name
resource "null_resource" "mkdir_tmp" {
  provisioner "local-exec" { command = "mkdir -p ${local.tmp_dir}" }
}

resource "talos_machine_secrets" "cluster" {}

data "talos_client_configuration" "client" {
  cluster_name         = var.cluster_name
  client_configuration = talos_machine_secrets.cluster.client_configuration
  nodes                = [var.bootstrap_node]
}

resource "azurerm_storage_blob" "talosconfig" {
  name                   = "${var.cluster_name}/talosconfig"
  storage_account_name   = var.storage_account_name
  storage_container_name = var.container_name
  type                   = "Block"
  content_type           = "text/plain"
  content                = data.talos_client_configuration.client.talos_config
}

data "talos_machine_configuration" "controlplane" {
  cluster_name     = var.cluster_name
  machine_type     = "controlplane"
  cluster_endpoint = var.cluster_endpoint
  machine_secrets  = talos_machine_secrets.cluster.machine_secrets
  config_patches   = [local.base_patch]
}

resource "local_file" "controlplane_local" {
  depends_on = [null_resource.mkdir_tmp]
  filename   = "${local.tmp_dir}/controlplane.yaml"
  content    = data.talos_machine_configuration.controlplane.machine_configuration
}

# Bootstrap the cluster (Talos provider) — runs only when bootstrap=true
resource "talos_machine_bootstrap" "cluster" {
  count               = var.bootstrap ? 1 : 0
  node                = var.bootstrap_node
  client_configuration = talos_machine_secrets.cluster.client_configuration
}

# Get kubeconfig after bootstrap
resource "talos_cluster_kubeconfig" "kc" {
  count               = var.bootstrap ? 1 : 0
  node                = var.bootstrap_node
  client_configuration = talos_machine_secrets.cluster.client_configuration
  depends_on          = [talos_machine_bootstrap.cluster]
}

# Write kubeconfig locally (only when bootstrap=true)
resource "local_file" "kubeconfig_local" {
  count      = var.bootstrap ? 1 : 0
  depends_on = [null_resource.mkdir_tmp, talos_cluster_kubeconfig.kc]
  filename   = "${local.tmp_dir}/kubeconfig"
  content    = talos_cluster_kubeconfig.kc[0].kubeconfig_raw
}