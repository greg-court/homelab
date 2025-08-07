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

resource "helm_release" "argocd" {
  name       = "argocd"
  namespace  = kubernetes_namespace.argocd.metadata[0].name
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = "8.2.5"

  create_namespace = false
  values           = [local.base_values]
}

resource "null_resource" "wait_argocd_ready" {
  depends_on = [helm_release.argocd]

  provisioner "local-exec" {
    command = "kubectl -n argocd rollout status sts/argocd-application-controller --timeout=180s"
  }

  # Ensure Argo CD generated its secret key (fixes those 'server.secretkey is missing' warnings)
  provisioner "local-exec" {
    command = "kubectl -n argocd get secret argocd-secret -o jsonpath='{.data.server\\.secretkey}' >/dev/null"
  }

  # Ensure the in-cluster kubeconfig exists when you set configs.clusters.inCluster.enabled=true
  provisioner "local-exec" {
    command = "kubectl -n argocd get secret argocd-manager-kubeconfig >/dev/null"
  }
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
  depends_on = [helm_release.argocd, null_resource.wait_argocd_ready]
}