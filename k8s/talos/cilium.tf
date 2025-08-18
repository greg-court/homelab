locals {
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

    hubble          = { enabled = true, relay = { enabled = true }, ui = { enabled = true } }
    l2announcements = { enabled = true }

    # Steer pod egress out specific NIC/VLANs
    egressGateway = { enabled = true }

    # Strongly recommended with multiple NIC/VLAN sub-interfaces
    devices = ["enp0s31f6", "enp0s31f6.3", "enp0s31f6.4", "enp0s31f6.5", "enp0s31f6.6"] # automate this list later based on interfaces & vlans
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
  depends_on      = [talos_cluster_kubeconfig.kc, talos_machine_bootstrap.cluster]
}
