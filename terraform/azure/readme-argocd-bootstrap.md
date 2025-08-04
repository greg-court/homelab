## Boostrap secret onto kubectl trust cluster

ensure correct kubectx

```bash
terraform output -raw eso_client_secret

kubectl create ns external-secrets 2>/dev/null || true # ignore if exists

kubectl -n external-secrets create secret generic azure-kv-creds \
 --from-literal=client-secret='<ESO_CLIENT_SECRET>'
```
