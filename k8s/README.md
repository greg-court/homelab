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

## Update all nodes

```
export TARGET=v1.11.2
export IMAGE="ghcr.io/siderolabs/installer:${TARGET}"

for n in n1 n2 n3; do
  echo ">>> upgrading $n"
  kubectl drain "$n" --ignore-daemonsets --delete-emptydir-data --force --grace-period=15 --timeout=30s
  talosctl upgrade -n "$n.klab.internal" --image "$IMAGE" --preserve --wait --force --timeout=30m
  kubectl uncordon "$n"
done

talosctl version --nodes n1.klab.internal,n2.klab.internal,n3.klab.internal
talosctl health
```

# ArgoCD commands

argocd login argocd.apps.klab.internal --username admin --password <password>
