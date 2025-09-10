k get pods -A -o wide

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

# On n1’s cilium pod (gateway will be lexicographically first labeled node):
kubectl -n kube-system exec -ti cilium-nb255 -- cilium-dbg bpf egress list

# Should show Source IP 10.244.0.38 (your netshoot) -> Gateway IP 192.168.2.231
# and on the gateway node it should list a non-zero Egress IP (your DHCP on bond0.5, e.g. 192.168.5.106).

# Watch for drops (they should disappear):
kubectl -n kube-system exec -ti cilium-nb255 -- sh -lc \
'hubble observe --since 45s --from-pod debug/netshoot-greg --to-ip 8.8.8.8 | head -n 30'
