Here. Barebones. Multi‑cluster safe. No sanity checks.

---

## 0. Reset

```bash
rm -f ~/.talos/config
```

---

## 1. Generate configs (separate dirs)

```bash
cd talos_config/cluster-trust
talosctl gen config cluster-trust https://k8s-ctrl-trust01.internal:6443 \
  --install-image factory.talos.dev/installer/ce4c980550dd2ab1b17bbf2b08801c7eb59418eafe8f279833297925d67c7515:v1.10.5
```

```bash
cd ../cluster-dmz
talosctl gen config cluster-dmz https://k8s-ctrl-dmz01.internal:6443 \
  --install-image factory.talos.dev/installer/ce4c980550dd2ab1b17bbf2b08801c7eb59418eafe8f279833297925d67c7515:v1.10.5
```

---

## 2. Terraform apply (provision nodes)

---

## 3. Bootstrap (one control node per cluster)

### cluster-trust

```bash
cd talos_config/cluster-trust
talosctl config merge ./talosconfig # writes `~/.talos/config`
talosctl config endpoint k8s-ctrl-trust01.internal
talosctl -n k8s-ctrl-trust01.internal bootstrap
```

### cluster-dmz

```bash
cd ../cluster-dmz
talosctl config merge ./talosconfig # writes `~/.talos/config`
talosctl config endpoint k8s-ctrl-dmz01.internal
talosctl -n k8s-ctrl-dmz01.internal bootstrap
```

---

## 4. Manage

```bash
talosctl config contexts # see contexts
talosctl config use-context cluster-trust # select trust context
talosctl config node k8s-ctrl-trust01.internal # select trust node
talosctl health
talosctl get services
talosctl dashboard --nodes k8s-ctrl.internal
talosctl dashboard --nodes k8s-infra.internal
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
