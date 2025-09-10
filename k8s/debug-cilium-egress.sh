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

kubectl -n kube-system exec -ti cilium-nb255 -- cilium-dbg status --verbose | egrep -i 'egress|masquerade|kube-proxy'
kubectl -n kube-system exec -ti cilium-nb255 -- cilium-dbg config | egrep -i 'enable-egress|enable-bpf-masquerade|kube-proxy-replacement|devices'

kubectl -n kube-system exec -ti cilium-nb255 -- cilium-dbg bpf egress list

kubectl -n kube-system exec -ti cilium-nb255 -- sh -lc 'id=$(cilium-dbg endpoint list | awk "$6==\"10.244.0.34\"{print \$1}"); echo EPID=$id; cilium-dbg bpf policy get "$id"'

kubectl -n kube-system exec -ti cilium-nb255 -- sh -lc 'cilium-dbg bpf nat list | head -n 50'
kubectl -n kube-system exec -ti cilium-nb255 -- sh -lc 'cilium-dbg bpf nat list | egrep -i "8\\.8\\.8\\.8|10\\.244\\.0\\.34" || true'

kubectl -n debug exec -ti netshoot-s8wd5 -- ip addr show bond0.5
kubectl -n debug exec -ti netshoot-s8wd5 -- ip route show
kubectl -n debug exec -ti netshoot-s8wd5 -- ping -I bond0.5 -c 3 8.8.8.8
