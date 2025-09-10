# paste your node IPs here
NODES=("192.168.2.231" "192.168.2.232" "192.168.2.233")

for n in "${NODES[@]}"; do
  echo "=== $n ==="
  # grab interface names from /proc/net/dev
  ifaces=$(talosctl -n "$n" read /proc/net/dev \
    | awk -F: 'NR>2 {gsub(/ /,"",$1); print $1}')

  for i in $ifaces; do
    mac=$(talosctl -n "$n" read "/sys/class/net/$i/address" 2>/dev/null || echo "?")
    state=$(talosctl -n "$n" read "/sys/class/net/$i/operstate" 2>/dev/null || echo "?")
    echo "$i  mac=$mac  state=$state"
  done
  echo
done

kubectl get ciliumegressgatewaypolicies.cilium.io
kubectl get ciliumegressgatewaypolicy egress-greg-vlan5 -o yaml | sed -n '1,120p'
kubectl get nodes -L egress-node

# KEY COMMAND
kubectl -n kube-system exec -ti cilium-nb255 -- sh -lc \
'hubble observe --since 1m --from-pod debug/netshoot-greg --to-ip 8.8.8.8 | head -n 30'
