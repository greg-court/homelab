## 0. Reset if desired

```bash
rm -f ~/.talos/config
# in each config directory:
talosctl config merge ./talosconfig
```

## 1. Kubeconfig

```bash
KUBECONFIG=~/.kube/config:./kubeconfig kubectl config view --flatten --merge > ~/.kube/config.tmp && mv ~/.kube/config.tmp ~/.kube/config
```

## 2. Manage

```bash
talosctl config contexts # see contexts
talosctl config use-context cluster-trust # select trust context
talosctl config node k8s-trust-01.internal # select trust node
talosctl health
talosctl get services
talosctl dashboard --nodes k8s-trust-01.internal
```

---

## 5. kubeconfig

```bash
talosctl config use-context cluster-trust # select trust context
talosctl kubeconfig .
cp ./kubeconfig ~/.kube/config
```

```bash
# merge cluster-dmz/kubeconfig
KUBECONFIG=~/.kube/config:cluster-dmz/kubeconfig kubectl config view --flatten --merge > ~/.kube/config.tmp && mv ~/.kube/config.tmp ~/.kube/config

# merge cluster-trust/kubeconfig
KUBECONFIG=~/.kube/config:cluster-trust/kubeconfig kubectl config view --flatten --merge > ~/.kube/config.tmp && mv ~/.kube/config.tmp ~/.kube/config

# Repeat in each cluster dir if you want both kubeconfigs (rename/context as needed).
# use K9S + kubectx for easier management
```
