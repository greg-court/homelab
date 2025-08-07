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

  # 1) Controller pod is up
  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-lc"]
    command     = "kubectl -n argocd rollout status sts/argocd-application-controller --timeout=180s"
  }

  # 2) CRB exists
  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-lc"]
    command     = <<-EOT
      set -euo pipefail
      for i in {1..60}; do
        if kubectl get clusterrolebinding argocd-application-controller -o name >/dev/null 2>&1; then
          exit 0
        fi
        sleep 3
      done
      echo "CRB argocd-application-controller not found" >&2
      exit 1
    EOT
  }

  # 3) SA RBAC actually works
  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-lc"]
    command     = <<-EOT
      set -euo pipefail
      for i in {1..60}; do
        if kubectl auth can-i --as=system:serviceaccount:argocd:argocd-application-controller list configmaps --all-namespaces \
           && kubectl auth can-i --as=system:serviceaccount:argocd:argocd-application-controller list secrets --all-namespaces; then
          exit 0
        fi
        sleep 3
      done
      echo "controller RBAC not effective yet" >&2
      exit 1
    EOT
  }

  # 4) server.secretkey present
  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-lc"]
    command     = <<-EOT
      set -euo pipefail
      for i in {1..60}; do
        if kubectl -n argocd get secret argocd-secret -o jsonpath='{.data.server\\.secretkey}' >/dev/null 2>&1; then
          exit 0
        fi
        sleep 3
      done
      echo "argocd-secret missing server.secretkey" >&2
      exit 1
    EOT
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