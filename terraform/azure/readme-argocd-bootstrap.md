## Boostrap secret onto kubectl trust cluster

ensure correct kubectx

```bash
terraform output -raw eso_client_secret

kubectl create ns external-secrets

kubectl -n external-secrets create secret generic azure-kv-creds \
  --from-literal=client-id='45818531-6511-4241-83a5-636240f15c5b' \
  --from-literal=tenant-id='a97d5792-e295-4539-9bf2-7260e2a90ad4' \
  --from-literal=client-secret='<ESO_CLIENT_SECRET>'
```
