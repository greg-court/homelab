module "argocd" {
  source  = "../-argocd"

  namespace               = "argocd"
  bootstrap_repo_url      = "https://github.com/greg-court/homelab.git"
  bootstrap_repo_path     = "k8s/gitops/clusters/dmz"

  extra_values_files      = ["${path.module}/argocd-values.yml"]
}

provider "kubernetes" {
  config_path = "../hosts/configs/cluster-dmz/kubeconfig"
}

provider "helm" {
  kubernetes = {
    config_path = "../hosts/configs/cluster-dmz/kubeconfig"
  }
}