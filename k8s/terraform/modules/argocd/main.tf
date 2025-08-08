terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">=2"
    }
    helm = {
      source  = "hashicorp/helm",
      version = ">=3"
    }
  }
}

resource "kubernetes_namespace" "argocd" {
  metadata { name = var.namespace }
}

locals {
  base_values = yamlencode({
    controller = {
      serverSideApply = { enabled = true } # this uses SSA for this helm chart only - NOT a global setting!
      rbac = { namespaced = false }
    }
    configs = {
      clusters = {
        inCluster = {
          enabled = true
          # When enabled the chart:
          #   - creates a ServiceAccount called `argocd-manager`
          #   - binds it (cluster-admin by default) so it can talk to the API
          #   - writes a kubeconfig for https://kubernetes.default.svc
          #     into a Secret the application-controller can read
          #
          # Without this kubeconfig Argo’s controller would reach the
          # API server unauthenticated and you’d see:
          #   “failed to get cluster info: the server has asked
          #    for the client to provide credentials”
        }
      }
    }
  })
}

resource "helm_release" "cilium" {
  name       = "cilium"
  namespace  = "kube-system"
  repository = "https://helm.cilium.io"
  chart      = "cilium"
  version    = "1.18.0"

  values = [yamlencode({
    ipam = { mode = "kubernetes" }

    # Full eBPF: replace kube-proxy
    kubeProxyReplacement = true

    # Talos: talk to the API via KubePrism (default port 7445)
    k8sServiceHost = "localhost"
    k8sServicePort = 7445

    # Native routing (no tunnel) — only if all nodes can route Pod CIDRs
    routingMode = "native"
    autoDirectNodeRoutes = true
    # Optionally help cilium detect the right interface or CIDR:
    # ipv4NativeRoutingCIDR = "10.244.0.0/16"

    # eBPF masquerade + bandwidth manager
    bpf = { masquerade = true }
    bandwidthManager = { enabled = true }

    # Talos-specific: cgroup mount + drop SYS_MODULE
    cgroup = {
      autoMount = { enabled = false }
      hostRoot  = "/sys/fs/cgroup"
    }
    securityContext = {
      capabilities = {
        ciliumAgent      = ["CHOWN","KILL","NET_ADMIN","NET_RAW","IPC_LOCK","SYS_ADMIN","SYS_RESOURCE","DAC_OVERRIDE","FOWNER","SETGID","SETUID"]
        cleanCiliumState = ["NET_ADMIN","SYS_ADMIN","SYS_RESOURCE"]
      }
    }

    hubble = { enabled = true, relay = { enabled = true }, ui = { enabled = true } }
  })]
}

resource "helm_release" "argocd" {
  name       = "argocd"
  namespace  = kubernetes_namespace.argocd.metadata[0].name
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = "8.2.5"

  create_namespace = false
  values           = [local.base_values]
  depends_on       = [helm_release.cilium]
}

# ---------- bootstrap “app-of-apps” -----------------------------------------
resource "kubernetes_manifest" "root_app" {
  manifest = {
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "Application"
    metadata = {
      name       = "root-apps"
      namespace  = kubernetes_namespace.argocd.metadata[0].name
      finalizers = ["resources-finalizer.argocd.argoproj.io"]
    }
    spec = {
      project = "default"
      destination = {
        server    = "https://kubernetes.default.svc"
        namespace = kubernetes_namespace.argocd.metadata[0].name
      }
      source = {
        repoURL        = var.bootstrap_repo_url
        targetRevision = var.bootstrap_repo_revision
        path           = var.bootstrap_repo_path
        directory      = { recurse = true }
      }
      syncPolicy = {
        automated   = { prune = true, selfHeal = true }
        syncOptions = ["CreateNamespace=true"]
      }
    }
  }
  depends_on = [helm_release.argocd]
}