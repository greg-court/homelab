# 0. One-liner install

```bash
kubectl create ns argocd
kubectl apply -n argocd \
  -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

# 1. Expose UI (port-forward or LB, your call)

```bash
kubectl -n argocd port-forward svc/argocd-server 8080:443 &
# or:
# kubectl -n argocd patch svc argocd-server -p '{"spec":{"type":"LoadBalancer"}}'
```

# 2. Get password

```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d
```

# 3. Tell Argo CD “this very cluster is a target”

```bash,
argocd cluster add in-cluster # auto-creates RBAC
```

# (for an external cluster, swap context name)

# 4. Bootstrap app-of-apps

```bash
argocd app create root-apps \
 --repo https://github.com/greg-court/homelab.git \
 --path k8s/gitops/clusters/trust \
 --dest-server https://kubernetes.default.svc \
 --dest-namespace argocd \
 --sync-policy automated
```
