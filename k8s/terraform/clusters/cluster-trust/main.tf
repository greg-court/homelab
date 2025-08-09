# cluster-bootstraps/trust/main.tf
module "argocd" {
  source = "../../modules/argocd"

  # cluster-local settings
  namespace           = "argocd"
  bootstrap_repo_url  = "https://github.com/greg-court/homelab.git"
  bootstrap_repo_path = "k8s/gitops/clusters/trust"
}