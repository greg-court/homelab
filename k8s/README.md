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

for n in n1.klab.internal n2.klab.internal n3.klab.internal; do
echo ">>> Cordon + drain $n"
  kubectl drain "$n" --ignore-daemonsets --delete-emptydir-data --force --grace-period=30 --timeout=10m

echo ">>> Upgrade Talos on $n"
  talosctl upgrade -n "$n" \
 --image ghcr.io/siderolabs/installer:${TARGET} \
 --wait --timeout=30m

echo ">>> Uncordon $n"
  kubectl uncordon "$n"
done

talosctl version --nodes n1.klab.internal,n2.klab.internal,n3.klab.internal
talosctl health
```
