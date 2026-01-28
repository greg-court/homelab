variable "namespace" { default = "argocd" }
variable "bootstrap_repo_url" {}
variable "bootstrap_repo_path" {}
variable "bootstrap_repo_revision" { default = "main" }
variable "enable_monitoring" {} # set to false before ArgoCD deploys apps

resource "kubernetes_namespace" "argocd" {
  metadata {
    name = var.namespace
  }
  depends_on = [local_file.kubeconfig_local, null_resource.wait_for_api]
}

locals {
  base_values = yamlencode({
    controller = {
      serverSideApply = { enabled = true }
      rbac            = { namespaced = false }
      metrics = {
        enabled = true
        serviceMonitor = {
          enabled   = var.enable_monitoring
          namespace = "monitoring"
        }
      }
    }
    server = {
      metrics = {
        enabled = true
        serviceMonitor = {
          enabled   = var.enable_monitoring
          namespace = "monitoring"
        }
      }
    }
    repoServer = {
      metrics = {
        enabled = true
        serviceMonitor = {
          enabled   = var.enable_monitoring
          namespace = "monitoring"
        }
      }
    }
    applicationSet = {
      enabled = true
      metrics = {
        enabled = true
        serviceMonitor = {
          enabled   = var.enable_monitoring
          namespace = "monitoring"
        }
      }
    }
    redis = {
      metrics = {
        enabled = true
        serviceMonitor = {
          enabled   = var.enable_monitoring
          namespace = "monitoring"
        }
      }
    }
    configs = {
      cm = {
        "accounts.admin" = "apiKey, login" # for mcp server
      }
      clusters = {
        inCluster = { enabled = true }
      }
    }
  })
}

resource "helm_release" "argocd" {
  name             = "argocd"
  namespace        = kubernetes_namespace.argocd.metadata[0].name
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  version          = "9.3.7"
  create_namespace = false
  values           = [local.base_values]
  wait             = true

  depends_on = [helm_release.cilium] # Cilium first
}

resource "helm_release" "argocd_root_apps" {
  name       = "argocd-root-apps"
  namespace  = kubernetes_namespace.argocd.metadata[0].name
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argocd-apps"

  values = [yamlencode({
    applications = {
      root-apps = {
        namespace = kubernetes_namespace.argocd.metadata[0].name
        project   = "default"
        source = {
          repoURL        = var.bootstrap_repo_url
          targetRevision = var.bootstrap_repo_revision
          path           = var.bootstrap_repo_path
          directory      = { recurse = true }
        }
        destination = {
          server    = "https://kubernetes.default.svc"
          namespace = kubernetes_namespace.argocd.metadata[0].name
        }
        syncPolicy = {
          automated   = { prune = true, selfHeal = true }
          syncOptions = ["CreateNamespace=true"]
        }
      }
    }
  })]

  depends_on = [helm_release.argocd, null_resource.wait_for_api]
}
