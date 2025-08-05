terraform {
  required_providers {
    kubernetes = {
      source = "hashicorp/kubernetes"
      version = ">=2"
      }
    helm       = {
      source = "hashicorp/helm",
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
      serverSideApply = { enabled = true } # <-- SSA ON, prevents large annotations causing issues
    }
    # configs = { # enabling this causes deployment to fail
    #   clusters = {
    #     inCluster = { enabled = true }
    #   }
    # }
  })
}

resource "helm_release" "argocd" {
  name       = "argocd"
  namespace  = kubernetes_namespace.argocd.metadata[0].name
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"

  create_namespace = false
  values           = [local.base_values]
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
        automated  = { prune = true, selfHeal = true }
        syncOptions = ["CreateNamespace=true"]
      }
    }
  }
  depends_on = [helm_release.argocd]
}