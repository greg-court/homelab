# Force reboot cluster

talosctl reboot \
 -n 192.168.2.231,192.168.2.232,192.168.2.233 \
 --mode=powercycle \
 --wait=false \
 --timeout=1m

# General K8s commands

k get pods -A -o wide

# Troubleshooting commands

kubectl -n argocd logs argocd-application-controller-0 --since=1h --timestamps | grep -Ei 'level(=|":")(warn|error|fatal)|\b(error|warn|failed|timeout|panic)\b'
