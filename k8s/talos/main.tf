locals {
  base_patch = yamlencode({
    machine = {
      sysctls = { # leniency on multi-homed reverse path
        "net.ipv4.conf.all.rp_filter"     = "2"
        "net.ipv4.conf.default.rp_filter" = "2"
      }
      nodeLabels = {
        "node.kubernetes.io/exclude-from-external-load-balancers" = {
          "$patch" = "delete"
        } # ensures no 'node.kubernetes.io/exclude-from-external-load-balancers: ""' on control planes
        "egress-node" = "true"
      }
      install = {
        disk = var.install_disk
        wipe = true
        image = "ghcr.io/siderolabs/installer:${var.talos_version}"
        extensions = [
          { image = "ghcr.io/siderolabs/iscsi-tools" },      # for longhorn
          { image = "ghcr.io/siderolabs/util-linux-tools" }, # for longhorn
          # { image = "ghcr.io/siderolabs/nfs-utils" }       # optional, if using RWX via Longhorn NFS
        ]
      }
      kernel = {
        modules = [
          { name = "iscsi_tcp" },     # for longhorn
          { name = "iscsi_generic" }, # for longhorn
          { name = "configfs" },      # for longhorn
          { name = "nbd" }            # for longhorn
        ]
      }
      features = {
        kubePrism = { enabled = true, port = 7445 }
        hostDNS   = { enabled = true, forwardKubeDNSToHost = false }
      }
      network = {
        interfaces = [{
          interface = "bond0"
          dhcp      = true
          vip       = { ip = "192.168.2.240" }
          bond = {
            mode           = "802.3ad"
            lacpRate       = "fast"
            xmitHashPolicy = "layer3+4"
            interfaces     = ["enP4p65s0", "enP3p49s0"] # putting NIC with DHCP reservation FIRST
          }
          vlans = [
            { vlanId = 3, dhcp = true },
            { vlanId = 4, dhcp = true },
            { vlanId = 5, dhcp = true },
            { vlanId = 6, dhcp = true }
          ]
        }]
      }
    }
    cluster = {
      allowSchedulingOnControlPlanes = true
      network                        = { cni = { name = "none" } }
      proxy                          = { disabled = true }
      apiServer = {
        certSANs = [
          var.api_server,
        ]
        extraArgs = {
          "service-account-issuer" = "https://kubernetes.default.svc"
          "api-audiences"          = "https://kubernetes.default.svc"
        }
        admissionControl = [
          # as per https://www.talos.dev/v1.10/kubernetes-guides/network/deploying-cilium/
          # and https://www.talos.dev/v1.10/kubernetes-guides/configuration/pod-security/
          # to allow cilium to run tests
          {
            name = "PodSecurity"
            configuration = {
              apiVersion = "pod-security.admission.config.k8s.io/v1alpha1"
              kind       = "PodSecurityConfiguration"
              defaults = {
                enforce         = "baseline"
                enforce-version = "latest"
                audit           = "restricted"
                audit-version   = "latest"
                warn            = "restricted"
                warn-version    = "latest"
              }
              exemptions = {
                usernames      = []
                runtimeClasses = []
                namespaces     = ["cilium-test-1"]
              }
            }
          }
        ]
      }
    }
  })
  ephemeral_patch = yamlencode({
    apiVersion = "v1alpha1"
    kind       = "VolumeConfig"
    name       = "EPHEMERAL"
    provisioning = {
      diskSelector = { match = "system_disk" }
      maxSize      = "64GiB"
      grow         = false
    }
  })
  tmp_dir = "${path.module}/tmp"
}

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

  source_content = data.talos_client_configuration.client.talos_config
}

resource "local_file" "talosconfig_local" {
  filename = "${local.tmp_dir}/talosconfig"
  content  = data.talos_client_configuration.client.talos_config
}


data "talos_machine_configuration" "controlplane" {
  cluster_name     = var.cluster_name
  machine_type     = "controlplane"
  talos_version    = var.talos_version
  cluster_endpoint = var.cluster_endpoint
  machine_secrets  = talos_machine_secrets.cluster.machine_secrets
  config_patches   = [local.base_patch, local.ephemeral_patch]
}

# not applied directly, just for reference
resource "local_file" "controlplane_baseline" {
  depends_on = [null_resource.mkdir_tmp]
  filename   = "${local.tmp_dir}/controlplane-baseline.yaml"
  content    = data.talos_machine_configuration.controlplane.machine_configuration
}

resource "local_file" "controlplane_per_node" {
  for_each = toset(var.hosts)
  filename = "${local.tmp_dir}/controlplane-${local.shortnames[each.value]}.yaml"
  content  = data.talos_machine_configuration.cp_per_node[each.value].machine_configuration
}

locals {
  shortnames = { for h in var.hosts : h => split(".", h)[0] }
}

data "talos_machine_configuration" "cp_per_node" {
  for_each         = toset(var.hosts)
  cluster_name     = var.cluster_name
  machine_type     = "controlplane"
  cluster_endpoint = var.cluster_endpoint
  machine_secrets  = talos_machine_secrets.cluster.machine_secrets
  talos_version    = var.talos_version

  config_patches = [
    local.base_patch,
    local.ephemeral_patch,
    yamlencode({
      machine = {
        # Limit SANs to this node’s FQDN + the VIP FQDN
        certSANs = [each.key, var.api_server]
        network  = { hostname = local.shortnames[each.key] }
      }
    }),
  ]
}


# Apply machine config to all CP nodes BEFORE bootstrap
resource "talos_machine_configuration_apply" "controlplanes" {
  for_each = toset(var.hosts)
  endpoint = each.value
  node     = each.value

  client_configuration        = talos_machine_secrets.cluster.client_configuration
  machine_configuration_input = data.talos_machine_configuration.cp_per_node[each.value].machine_configuration
  apply_mode                  = "auto"
}

# Bootstrap the cluster (Talos provider)
resource "talos_machine_bootstrap" "cluster" {
  node                 = var.bootstrap_node
  client_configuration = talos_machine_secrets.cluster.client_configuration
  depends_on           = [talos_machine_configuration_apply.controlplanes]
}

# Get kubeconfig after bootstrap
resource "talos_cluster_kubeconfig" "kc" {
  node                 = var.bootstrap_node
  client_configuration = talos_machine_secrets.cluster.client_configuration
  depends_on           = [talos_machine_bootstrap.cluster]
}

# Write kubeconfig locally (only when bootstrap=true)
resource "local_file" "kubeconfig_local" {
  depends_on = [null_resource.mkdir_tmp, talos_cluster_kubeconfig.kc]
  filename   = "${local.tmp_dir}/kubeconfig"
  content    = talos_cluster_kubeconfig.kc.kubeconfig_raw
}

resource "null_resource" "wait_for_api" {
  depends_on = [local_file.kubeconfig_local]
  provisioner "local-exec" {
    command = <<EOT
    for i in $(seq 1 60); do
      nc -zvw2 api.klab.internal 6443 && exit 0
      sleep 2
    done
    echo "API not ready" >&2; exit 1
    EOT
  }
}