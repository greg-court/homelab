## Boostrap secret onto kubectl trust cluster

ensure correct kubectx

```bash
terraform output -raw eso_client_secret

kubectl create ns external-secrets 2>/dev/null || true # ignore if exists

kubectl -n external-secrets create secret generic azure-kv-creds \
 --from-literal=client-secret='<ESO_CLIENT_SECRET>'
```

## Get temporary access to ArgoCD GUI while you configure LBs

```bash

kubectl -n argocd port-forward svc/argocd-server 8080:443
```

## Get argocd credentials

```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

Then go to https://localhost:8080
