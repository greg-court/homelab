terraform {
  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = ">= 3"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2"
    }
  }
}

resource "kubernetes_namespace" "argocd" {
  metadata {
    name = var.argocd_namespace
  }
}

# ---- Install Argo CD via Helm -----

resource "helm_release" "argocd" {
  name             = "argocd"
  namespace        = kubernetes_namespace.argocd.metadata[0].name
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  create_namespace = false

  # Minimal values override; extend as needed
  values = [
    yamlencode({
      global = {
        image = {
          # let chart default decide tag; you can pin here if you want
        }
      }
      configs = {
        params = {
          "server.insecure" = "false"
        }
      }
      server = {
        service = {
          type = "ClusterIP"
        }
      }
    })
  ]
}

# ---- Bootstrap Project ------------

resource "kubernetes_manifest" "bootstrap_project" {
  manifest = {
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "AppProject"
    metadata = {
      name       = "bootstrap"
      namespace  = kubernetes_namespace.argocd.metadata[0].name
      finalizers = ["resources-finalizer.argocd.argoproj.io"]
    }
    spec = {
      description = "Project for initial cluster bootstrap"
      sourceRepos = ["*"]
      destinations = [
        {
          server    = "https://kubernetes.default.svc"
          namespace = "*"
        }
      ]
      clusterResourceWhitelist = [
        {
          group = "*"
          kind  = "*"
        }
      ]
    }
  }

  depends_on = [helm_release.argocd]
}

# ---- Root Application (App of Apps)

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
      project = "bootstrap"

      destination = {
        server    = "https://kubernetes.default.svc"
        namespace = kubernetes_namespace.argocd.metadata[0].name
      }

      source = {
        repoURL        = var.bootstrap_repo_url
        targetRevision = var.bootstrap_repo_revision
        path           = var.bootstrap_repo_path
        directory = {
          recurse = true
        }
      }

      syncPolicy = {
        automated = {
          prune    = true
          selfHeal = true
        }
        syncOptions = [
          "CreateNamespace=true"
        ]
      }
    }
  }

  depends_on = [kubernetes_manifest.bootstrap_project]
}
