terraform {
  required_providers {
    kubernetes = { source = "hashicorp/kubernetes", version = ">= 2" }
    helm       = { source = "hashicorp/helm", version = ">= 3" }
  }
}

module "argocd" {
  source = "../../modules/argocd"

  namespace           = "argocd"
  bootstrap_repo_url  = "https://github.com/greg-court/homelab.git"
  bootstrap_repo_path = "k8s/gitops/clusters/dmz"
}