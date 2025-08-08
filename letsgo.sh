#!/usr/bin/env bash
set -euo pipefail

# Figure out where 'gitops' root is (supports both repo layouts you've shown)
if [ -d "k8s/gitops" ]; then
  BASE="k8s/gitops"
elif [ -d "gitops" ]; then
  BASE="gitops"
else
  echo "Could not find 'gitops' or 'k8s/gitops' directory. Run from repo root."
  exit 1
fi

echo "Using base path: $BASE"

# 1) Remove NGINX controller + helper ingress-app chart + NGINX-based exposures
rm -rf "$BASE/charts/ingress-app" || true
rm -f  "$BASE/clusters/trust/30-ingress-nginx.yml" \
       "$BASE/clusters/dmz/30-ingress-nginx.yml" \
       "$BASE/clusters/trust/40-expose-argocd.yml" \
       "$BASE/clusters/trust/40-expose-hubble.yml" || true

# Ensure target dirs exist
mkdir -p "$BASE/clusters/trust" "$BASE/clusters/dmz" \
         "$BASE/apps/expose-argocd" "$BASE/apps/expose-hubble"

# 2) Update AppProjects: remove NGINX repo, add Traefik repo
for P in "$BASE/clusters/trust/00-project-platform.yml" "$BASE/clusters/dmz/00-project-platform.yml"; do
  [ -f "$P" ] || continue
  # Drop ingress-nginx repo line if present
  sed -i '' '/https:\/\/kubernetes.github.io\/ingress-nginx/d' "$P"
  # Add Traefik repo if missing (append under sourceRepos)
  if ! grep -q 'https://traefik.github.io/charts' "$P"; then
    awk '
      BEGIN{added=0}
      {print}
      /sourceRepos:/ { sr=1; next }
      sr==1 && $0 ~ /^  clusterResourceWhitelist:/ && added==0 {
        print "  sourceRepos:"
        print "    - https://traefik.github.io/charts"
        sr=0; added=1; next
      }
    ' "$P" > "$P.tmp" && mv "$P.tmp" "$P"
    # If above insertion heuristic didn’t match (layout differs), append safely:
    if ! grep -q 'https://traefik.github.io/charts' "$P"; then
      # naive append at end of sourceRepos list
      perl -0777 -pe 's/(sourceRepos:\s*\n(?:\s*-\s*\S+\s*\n)+)/$1    - https:\/\/traefik.github.io\/charts\n/s' "$P" > "$P.tmp" && mv "$P.tmp" "$P"
    fi
  fi
done

# 3) Traefik CRDs (sync wave -11)
cat > "$BASE/clusters/trust/29-traefik-crds.yml" <<'YAML'
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: traefik-crds
  namespace: argocd
  annotations: { argocd.argoproj.io/sync-wave: "-11" }
spec:
  project: platform
  destination: { server: https://kubernetes.default.svc, namespace: traefik }
  source:
    repoURL: https://traefik.github.io/charts
    chart: traefik-crds
    targetRevision: 17.0.0
  syncPolicy:
    automated: { prune: true, selfHeal: true }
    syncOptions: [ "CreateNamespace=true" ]
YAML

cat > "$BASE/clusters/dmz/29-traefik-crds.yml" <<'YAML'
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: traefik-crds
  namespace: argocd
  annotations: { argocd.argoproj.io/sync-wave: "-11" }
spec:
  project: platform
  destination: { server: https://kubernetes.default.svc, namespace: traefik }
  source:
    repoURL: https://traefik.github.io/charts
    chart: traefik-crds
    targetRevision: 17.0.0
  syncPolicy:
    automated: { prune: true, selfHeal: true }
    syncOptions: [ "CreateNamespace=true" ]
YAML

# 4) Traefik controller (sync wave -10), MetalLB VIPs + HTTPS redirect
cat > "$BASE/clusters/trust/30-traefik.yml" <<'YAML'
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: traefik
  namespace: argocd
  annotations: { argocd.argoproj.io/sync-wave: "-10" }
spec:
  project: platform
  destination:
    server: https://kubernetes.default.svc
    namespace: traefik
  source:
    repoURL: https://traefik.github.io/charts
    chart: traefik
    targetRevision: 37.0.0
    helm:
      values: |
        service:
          type: LoadBalancer
          annotations:
            metallb.io/address-pool: trust-pool
            metallb.io/loadBalancerIPs: "192.168.3.250"
        additionalArguments:
          - "--entrypoints.web.http.redirections.entrypoint.to=websecure"
          - "--entrypoints.web.http.redirections.entrypoint.scheme=https"
  syncPolicy:
    automated: { prune: true, selfHeal: true }
    syncOptions: [ "CreateNamespace=true" ]
YAML

cat > "$BASE/clusters/dmz/30-traefik.yml" <<'YAML'
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: traefik
  namespace: argocd
  annotations: { argocd.argoproj.io/sync-wave: "-10" }
spec:
  project: platform
  destination:
    server: https://kubernetes.default.svc
    namespace: traefik
  source:
    repoURL: https://traefik.github.io/charts
    chart: traefik
    targetRevision: 37.0.0
    helm:
      values: |
        service:
          type: LoadBalancer
          annotations:
            metallb.io/address-pool: dmz-pool
            metallb.io/loadBalancerIPs: "192.168.4.250"
        additionalArguments:
          - "--entrypoints.web.http.redirections.entrypoint.to=websecure"
          - "--entrypoints.web.http.redirections.entrypoint.scheme=https"
  syncPolicy:
    automated: { prune: true, selfHeal: true }
    syncOptions: [ "CreateNamespace=true" ]
YAML

# 5) Expose Argo CD via Traefik CRDs
cat > "$BASE/apps/expose-argocd/kustomization.yaml" <<'YAML'
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - servers-transport.yaml
  - certificate.yaml
  - ingressroute.yaml
YAML

cat > "$BASE/apps/expose-argocd/servers-transport.yaml" <<'YAML'
apiVersion: traefik.io/v1alpha1
kind: ServersTransport
metadata:
  name: https-insecure
  namespace: argocd
spec:
  insecureSkipVerify: true
YAML

cat > "$BASE/apps/expose-argocd/certificate.yaml" <<'YAML'
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: argocd-trust-tls-cert
  namespace: argocd
spec:
  secretName: argocd-trust-tls
  dnsNames: [ "argocd.trust.k8s.internal" ]
  issuerRef: { kind: ClusterIssuer, name: homelab-ca }
YAML

cat > "$BASE/apps/expose-argocd/ingressroute.yaml" <<'YAML'
apiVersion: traefik.io/v1alpha1
kind: IngressRoute
metadata:
  name: argocd
  namespace: argocd
spec:
  entryPoints: [ "websecure" ]
  routes:
    - match: Host(`argocd.trust.k8s.internal`)
      kind: Rule
      services:
        - name: argocd-server
          port: 443
          scheme: https
          serversTransport: https-insecure
  tls:
    secretName: argocd-trust-tls
YAML

# 6) Expose Hubble UI via Traefik CRDs (HTTP backend)
cat > "$BASE/apps/expose-hubble/kustomization.yaml" <<'YAML'
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - certificate.yaml
  - ingressroute.yaml
YAML

cat > "$BASE/apps/expose-hubble/certificate.yaml" <<'YAML'
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: hubble-trust-tls-cert
  namespace: kube-system
spec:
  secretName: hubble-trust-tls
  dnsNames: [ "hubble.trust.k8s.internal" ]
  issuerRef: { kind: ClusterIssuer, name: homelab-ca }
YAML

cat > "$BASE/apps/expose-hubble/ingressroute.yaml" <<'YAML'
apiVersion: traefik.io/v1alpha1
kind: IngressRoute
metadata:
  name: hubble
  namespace: kube-system
spec:
  entryPoints: [ "websecure" ]
  routes:
    - match: Host(`hubble.trust.k8s.internal`)
      kind: Rule
      services:
        - name: hubble-ui
          port: 80
  tls:
    secretName: hubble-trust-tls
YAML

# 7) Argo CD Applications for the exposures (keep same sync-wave 10)
cat > "$BASE/clusters/trust/40-expose-argocd.yml" <<'YAML'
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: expose-argocd
  namespace: argocd
  annotations: { argocd.argoproj.io/sync-wave: "10" }
spec:
  project: platform
  destination: { server: https://kubernetes.default.svc, namespace: argocd }
  source:
    repoURL: https://github.com/greg-court/homelab.git
    targetRevision: main
    path: k8s/gitops/apps/expose-argocd
  syncPolicy:
    automated: { prune: true, selfHeal: true }
YAML

cat > "$BASE/clusters/trust/40-expose-hubble.yml" <<'YAML'
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: expose-hubble
  namespace: argocd
  annotations: { argocd.argoproj.io/sync-wave: "10" }
spec:
  project: platform
  destination: { server: https://kubernetes.default.svc, namespace: kube-system }
  source:
    repoURL: https://github.com/greg-court/homelab.git
    targetRevision: main
    path: k8s/gitops/apps/expose-hubble
  syncPolicy:
    automated: { prune: true, selfHeal: true }
YAML

# 8) README: rename ingress-nginx -> traefik in the apply order
if [ -f "$BASE/readme.md" ]; then
  sed -i '' 's/ingress-nginx/traefik/g' "$BASE/readme.md"
fi

echo "Done. Review git changes, commit, then let Argo CD sync."
echo "Quick checks after sync:"
echo "  - kubectl -n traefik get svc traefik -o wide   # expect 192.168.3.250 (trust) or 192.168.4.250 (dmz)"
echo "  - kubectl get ingressroute.traefik.io -A"
echo "  - curl -vk https://argocd.trust.k8s.internal/"
