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
      rbac            = { namespaced = false }
    }
    configs = {
      clusters = {
        inCluster = {
          enabled = true
          # When incluster is enabled the chart:
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


# 1) Install Argo CD (installs CRDs)
resource "helm_release" "argocd" {
  name       = "argocd"
  namespace  = kubernetes_namespace.argocd.metadata[0].name
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = "8.3.0"

  create_namespace = false
  values           = [local.base_values]
  wait             = true
}

# 2) Bootstrap the root app using argocd-apps chart (avoids CRD race)
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