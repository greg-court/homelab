# Platform GitOps

## DNS (pfSense / Unbound)

- trust: `*.trust.k8s.internal -> 192.168.3.250`
- dmz: `*.dmz.k8s.internal   -> 192.168.4.250`

## Apply order

Argo CD's app-of-apps handles order via sync waves:

1. cert-manager (CRDs)
2. cert-issuers (root CA + ClusterIssuer)
3. metallb and metallb-config (VIPs)
4. traefik
5. exposures (Argocd, Hubble, etc.)
6. external-secrets + app stacks

## Add a new UI (example: grafana on TRUST)

Create `clusters/trust/41-expose-grafana.yml` using charts/ingress-app:

```yaml
# clusters/trust/41-expose-grafana.yml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: expose-grafana
  namespace: argocd
  annotations: { argocd.argoproj.io/sync-wave: '12' }
spec:
  project: platform
  destination: { server: https://kubernetes.default.svc, namespace: grafana }
  source:
    repoURL: https://github.com/greg-court/homelab.git
    targetRevision: main
    path: k8s/gitops/apps/expose-grafana
  syncPolicy:
    automated: { prune: true, selfHeal: true }
```
