locals {
  cilium_config = [yamlencode({
    ipam = { mode = "kubernetes" }

    ipv4NativeRoutingCIDR = "10.244.0.0/16"

    # Full eBPF: replace kube-proxy
    kubeProxyReplacement = true

    # Talos: talk to the API via KubePrism (default port 7445)
    k8sServiceHost = "localhost"
    k8sServicePort = 7445

    # Native routing (no tunnel) — only if all nodes can route Pod CIDRs
    routingMode          = "native"
    autoDirectNodeRoutes = true

    # eBPF masquerade + bandwidth manager
    bpf              = { masquerade = true }
    bandwidthManager = { enabled = true }

    # Talos-specific: cgroup mount + drop SYS_MODULE
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

    hubble = { enabled = true, relay = { enabled = true }, ui = { enabled = true } }
  })]
}

# Wait a bit after the API is reachable for TRUST
resource "time_sleep" "after_bootstrap_trust" {
  create_duration = "60s"
  depends_on      = [talos_cluster_kubeconfig.kc["cluster-trust"]]
}

# Wait a bit after the API is reachable for DMZ
resource "time_sleep" "after_bootstrap_dmz" {
  create_duration = "60s"
  depends_on      = [talos_cluster_kubeconfig.kc["cluster-dmz"]]
}

resource "helm_release" "cilium_trust" {
  provider        = helm.trust
  name            = "cilium"
  namespace       = "kube-system"
  repository      = "https://helm.cilium.io"
  chart           = "cilium"
  version         = "1.18.1"
  values          = local.cilium_config
  timeout         = 600
  atomic          = true
  cleanup_on_fail = true

  depends_on = [local_file.kubeconfig_out["cluster-trust"], talos_cluster_kubeconfig.kc, time_sleep.after_bootstrap_trust]
}

resource "helm_release" "cilium_dmz" {
  provider        = helm.dmz
  name            = "cilium"
  namespace       = "kube-system"
  repository      = "https://helm.cilium.io"
  chart           = "cilium"
  version         = "1.18.1"
  values          = local.cilium_config
  timeout         = 600
  atomic          = true
  cleanup_on_fail = true

  depends_on = [local_file.kubeconfig_out["cluster-dmz"], talos_cluster_kubeconfig.kc, time_sleep.after_bootstrap_dmz]
}