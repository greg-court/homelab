# cluster-bootstraps/trust/main.tf
module "argocd" {
  source  = "../argocd"

  # cluster-local settings
  namespace               = "argocd"
  bootstrap_repo_url      = "https://github.com/greg-court/homelab.git"
  bootstrap_repo_path     = "k8s/gitops/clusters/trust"

  # make Argo CD register “in-cluster” automatically
  extra_values_files = ["${path.module}/argocd-values.yml"]
}

# providers (re-use your Talos-generated kubeconfig)
provider "kubernetes" {
  config_path = "../hosts/configs/cluster-trust/kubeconfig"
}

provider "helm" {
  kubernetes = {
    config_path = "../hosts/configs/cluster-trust/kubeconfig"
  }
}