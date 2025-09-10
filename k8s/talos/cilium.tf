locals {
  base_interface = yamldecode(local.base_patch).machine.network.interfaces[0].interface
  vlans = [
    for v in yamldecode(local.base_patch).machine.network.interfaces[0].vlans : v.vlanId
  ]
  cilium_devices = concat(
    [local.base_interface],
    [for v in local.vlans : "${local.base_interface}.${v}"]
  )
  cilium_config = [yamlencode({
    ipam = { mode = "kubernetes" }

    ipv4NativeRoutingCIDR = "10.244.0.0/16"

    kubeProxyReplacement = true
    k8sServiceHost       = "localhost"
    k8sServicePort       = 7445

    routingMode          = "native"
    autoDirectNodeRoutes = true

    bpf              = { masquerade = true }
    bandwidthManager = { enabled = true }

    cgroup = {
      autoMount = { enabled = false }
      hostRoot  = "/sys/fs/cgroup"
    }
    securityContext = {
      capabilities = {
        ciliumAgent      = ["CHOWN", "KILL", "NET_ADMIN", "NET_RAW", "IPC_LOCK", "SYS_ADMIN", "SYS_RESOURCE", "DAC_OVERRIDE", "FOWNER", "SETGID", "SETUID"]
        cleanCiliumState = ["NET_ADMIN", "SYS_ADMIN", "SYS_RESOURCE"]
      }
    }

    hubble = {
      enabled = true
      relay   = { enabled = true }
      ui      = { enabled = true }

      # ➜ Enable Hubble metrics + ServiceMonitor
      metrics = {
        enabled = [
          "dns:query;ignoreAAAA",
          "drop",
          "tcp",
          "icmp"
        ]
      }
      metricsServer = {
        enabled        = true
        serviceMonitor = { enabled = var.enable_monitoring }
      }
    }

    l2announcements = { enabled = true }

    # ➜ Cilium agent metrics + ServiceMonitor
    prometheus = {
      enabled        = true
      serviceMonitor = { enabled = var.enable_monitoring }
    }

    # ➜ Cilium operator metrics + ServiceMonitor
    operator = {
      prometheus = {
        enabled        = true
        serviceMonitor = { enabled = var.enable_monitoring }
      }
    }

    # Steer pod egress out specific NIC/VLANs
    egressGateway = { enabled = true }
    devices       = local.cilium_devices
  })]
}

resource "helm_release" "cilium" {
  name            = "cilium"
  namespace       = "kube-system"
  repository      = "https://helm.cilium.io"
  chart           = "cilium"
  version         = "1.18.1"
  values          = local.cilium_config
  timeout         = 600
  atomic          = true
  cleanup_on_fail = true
  depends_on      = [talos_cluster_kubeconfig.kc, talos_machine_bootstrap.cluster, null_resource.wait_for_api]
}

# output cilium_devices
output "cilium_devices" {
  value = local.cilium_devices
}