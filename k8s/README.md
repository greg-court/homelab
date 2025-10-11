# Force reboot cluster

talosctl reboot \
 -n 192.168.2.231,192.168.2.232,192.168.2.233 \
 --mode=powercycle \
 --wait=false \
 --timeout=1m

# General K8s commands

k get pods -A -o wide

# Kubernetes troubleshooting commands

kubectl -n argocd logs argocd-application-controller-0 --since=1h --timestamps | grep -Ei 'level(=|":")(warn|error|fatal)|\b(error|warn|failed|timeout|panic)\b'

# Talos troubleshooting commands

## Force reboot

talosctl reboot --mode powercycle --wait=false --nodes n1.klab.internal,n2.klab.internal,n3.klab.internal

## Update nodes to new installer image

```
talosctl -n n1.klab.internal upgrade \
  --image factory.talos.dev/metal-installer/80617d0e416b08d3ee0f06f52fb21db36a823f9135fb3e1b735fa65dd1a87632:v1.11.2 \
  --preserve=true --wait
```

# ArgoCD commands

argocd login argocd.apps.klab.internal --username admin --password <password>
