module "argocd" {
  source               = "../tf-modules/k8-argocd"
  namespace            = "argocd"
  bootstrap_repo_url   = "https://github.com/greg-court/homelab.git"
  bootstrap_repo_path  = "k8s/gitops/clusters/trust"
}