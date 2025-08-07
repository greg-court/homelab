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
  # ------------------------------------------------------------
  # Argo CD must have credentials for the API server it deploys to.
  # Setting `configs.clusters.inCluster.enabled = true` tells the Helm
  # chart to:
  #   - create a service-account called `argocd-manager`
  #   - bind it to cluster-admin (or the RBAC you override)
  #   - generate a kubeconfig and store it in a secret named `cluster-kubernetes-default-svc-<uid>`
  #
  # Without this secret the application-controller talks to
  # https://kubernetes.default.svc with no credentials, which
  # surfaces as:
  #   “failed to get cluster info … the server has asked for the
  #    client to provide credentials”
  # ------------------------------------------------------------
  base_values = yamlencode({
    controller = {
      serverSideApply = { enabled = true } # <-- SSA ON, prevents large annotations causing issues
    }
    # 1.  create the SA
    configs = {
      clusters = {
        inCluster = { enabled = true }
      }
      # 2.  tell the chart to run the hook that writes the Secret
      clusterCredentials = {
        enabled = true
      }
    }
    # 3.  give the API server read access so argocd-server stops “Unauthorized”
    server = {
      rbac = { namespaced = false }
    }
  })
}

resource "helm_release" "argocd" {
  name       = "argocd"
  namespace  = kubernetes_namespace.argocd.metadata[0].name
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = "8.2.5"

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