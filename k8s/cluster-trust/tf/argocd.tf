module "argocd" {
  source = "../../tf-modules/k8-argocd"
  namespace = "argocd"
}