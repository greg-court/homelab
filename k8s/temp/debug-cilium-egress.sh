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

echo "general cilium info:"
kubectl get ciliumegressgatewaypolicies.cilium.io
kubectl get ciliumegressgatewaypolicy egress-v5-greg -o yaml | sed -n '1,120p'
kubectl get nodes -L egress-node

echo "on n1's cilium pod (gateway will be lexicographically first labeled node):"
kubectl -n kube-system exec -ti cilium-5swfb -- cilium-dbg bpf egress list

# Should show Source IP 10.244.0.38 (your netshoot) -> Gateway IP 192.168.2.231
# and on the gateway node it should list a non-zero Egress IP (your DHCP on bond0.5, e.g. 192.168.5.106).

echo "Watch for drops (they should disappear):"
kubectl -n kube-system exec -ti cilium-5swfb -- sh -lc \
'hubble observe --since 45s --from-pod debug/netshoot-greg --to-ip 8.8.8.8 | head -n 30'

echo "check if cilium is aware of the bond NICs (not 100% sure about this command):"
kubectl -n kube-system get ds cilium -o jsonpath='{.spec.template.spec.containers[0].args}' | xargs -n1
kubectl -n kube-system exec -ti cilium-5swfb -- cilium-dbg config | egrep 'device'

echo "check what cilium is reading from its configmap:"
kubectl -n kube-system get cm cilium-config -o yaml | sed -n '1,180p'

echo "check egress BPF maps and bond0.5 IP:"
kubectl -n kube-system exec -ti cilium-5swfb -- cilium-dbg bpf egress list
kubectl -n kube-system exec -ti cilium-5swfb -- ip -4 addr show dev bond0.5
kubectl -n kube-system exec -ti cilium-5swfb -- cilium-dbg config | grep -i '^devices\|masquerade'

# Agent logs on the gateway node; look for egress selection lines / errors
kubectl -n kube-system logs cilium-5swfb -c cilium-agent --since=10m | \
  egrep -i 'egress|gateway|egress ip|policy'

# Full agent status
kubectl -n kube-system exec -ti cilium-5swfb -- cilium-dbg status --verbose

# NAT / SNAT stats (can reveal oddities)
kubectl -n kube-system exec -ti ds/cilium -- cilium-dbg shell -- db/show nat-stats