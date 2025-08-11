## 0. Reset if desired

```bash
rm -f ~/.talos/config && rm -f ~/.kube/config
```

## 1. Talosconfig

```bash
# in each config directory:
cd ./configs/cluster-dmz && talosctl config merge ./talosconfig
cd ../cluster-trust && talosctl config merge ./talosconfig
```

## 2. Kubeconfig

```bash
cd ..
# merge cluster-dmz/kubeconfig
KUBECONFIG=~/.kube/config:cluster-dmz/kubeconfig kubectl config view --flatten --merge > ~/.kube/config.tmp && mv ~/.kube/config.tmp ~/.kube/config

# merge cluster-trust/kubeconfig
KUBECONFIG=~/.kube/config:cluster-trust/kubeconfig kubectl config view --flatten --merge > ~/.kube/config.tmp && mv ~/.kube/config.tmp ~/.kube/config
```

## 3. Manage

```bash
talosctl config contexts # see contexts
talosctl config use-context cluster-trust # select trust context
talosctl config node k8s-trust-01.internal # select trust node
talosctl config endpoints k8s-trust-01.internal
talosctl health
talosctl get services
talosctl dashboard --nodes k8s-trust-01.internal
```

```bash
# Get all passwords
kubectl get secrets --all-namespaces -o json \
  | jq -r '.items[] | select(.data | has("password")) | "\(.metadata.namespace) \(.metadata.name): " + (.data.password | @base64d)'
```

---
