####################  MetalLB chart  ####################
resource "kubernetes_namespace_v1" "metallb" {
  metadata {
    name   = "metallb-system"
    labels = {
      "pod-security.kubernetes.io/enforce"         = "privileged"
      "pod-security.kubernetes.io/enforce-version" = "latest"
      "pod-security.kubernetes.io/warn"            = "baseline"
      "pod-security.kubernetes.io/audit"           = "baseline"
    }
  }
}

resource "helm_release" "metallb" {
  name       = "metallb"
  repository = "https://metallb.github.io/metallb"
  chart      = "metallb"
  version    = "0.15.2"
  namespace  = kubernetes_namespace_v1.metallb.metadata[0].name
  depends_on = [kubernetes_namespace_v1.metallb]
}