resource "helm_release" "traefik_crds" {
  name       = "traefik-crds"
  chart      = "traefik"
  repository = "https://traefik.github.io/charts"
  version    = "36.3.0"
  namespace  = "traefik-system"
  create_namespace = true

  values = [<<YAML
deployment:
  enabled: false
service:
  enabled: false
ingressRoute:
  dashboard:
    enabled: false
YAML
  ]
}
