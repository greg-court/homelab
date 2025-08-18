variable "namespace" { default = "argocd" }
variable "bootstrap_repo_url" {}
variable "bootstrap_repo_path" {}
variable "bootstrap_repo_revision" { default = "main" }

resource "kubernetes_namespace" "argocd" {
  metadata {
    name = var.namespace
  }
  depends_on = [local_file.kubeconfig_local]
}

locals {
  base_values = yamlencode({
    controller = {
      serverSideApply = { enabled = true }
      rbac            = { namespaced = false }
    }
    configs = { clusters = { inCluster = { enabled = true } } }
    global = {
      podLabels = { egress.zone = "trust" }
    }
  })
}

resource "helm_release" "argocd" {
  name             = "argocd"
  namespace        = kubernetes_namespace.argocd.metadata[0].name
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  version          = "8.3.0"
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

  depends_on = [helm_release.argocd]
}
