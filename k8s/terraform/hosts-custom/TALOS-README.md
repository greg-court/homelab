# Talos cluster bootstrap (runbook)

---

## 0. Clean slate (optional)

```bash
rm -f ~/.talos/config
```

This only wipes your local Talos CLI config.
Nothing on the nodes or in Terraform state is touched.

---

## 1. Generate _base_ Talos configs — **once per Talos version**

> **Why still manual?**
> We still need `controlplane.yaml` (and `worker.yaml` if you add workers).
> Terraform re-uses these templates and patches them per-node.
> The `talosconfig` artefact that `talosctl gen config` creates will be
> overwritten by Terraform, so you can ignore it.

```bash
# cluster-trust
cd talos_config/cluster-trust
talosctl gen config cluster-trust https://k8s-svc-01.internal:6443 \
  --install-image factory.talos.dev/installer/ce4c980550dd2ab1b17bbf2b08801c7eb59418eafe8f279833297925d67c7515:v1.10.5
```

```bash
# cluster-dmz
cd ../cluster-dmz
talosctl gen config cluster-dmz https://k8s-dmz-01.internal:6443 \
  --install-image factory.talos.dev/installer/ce4c980550dd2ab1b17bbf2b08801c7eb59418eafe8f279833297925d67c7515:v1.10.5
```

Commit those two YAMLs — they rarely change.

---

## 2. `terraform apply` — _everything else is automated_

```bash
terraform init
terraform apply -auto-approve   # creates VMs, uploads per-node snippets,
                                # generates cluster talosconfig files, etc.
```

_Terraform writes fresh `talos_config/cluster-_/talosconfig` files.\*

---

## 3. Bootstrap **one** control-plane node per cluster

### cluster-trust

```bash
cd talos_config/cluster-trust
talosctl config merge ./talosconfig          # populates ~/.talos/config
talosctl config endpoint  k8s-svc-01.internal
talosctl -n k8s-svc-01.internal bootstrap
```

### cluster-dmz

```bash
cd ../cluster-dmz
talosctl config merge ./talosconfig
talosctl config endpoint  k8s-dmz-01.internal
talosctl -n k8s-dmz-01.internal bootstrap
```

> After the bootstrap finishes, etcd comes up and all other control-plane
> nodes will automatically join.

---

## 4. Day-2 operations

```bash
# list contexts Terraform wrote for you
talosctl config contexts

talosctl config use-context cluster-trust
talosctl health
talosctl get machines
talosctl dashboard --nodes k8s-svc-01.internal
```

Switch contexts (`cluster-dmz`) as needed.

---

## 5. Grab / merge kubeconfigs

```bash
# cluster-trust
talosctl config use-context cluster-trust
talosctl kubeconfig .
cp ./kubeconfig ~/.kube/config
```

```bash
# add cluster-dmz to the same ~/.kube/config
KUBECONFIG=~/.kube/config:../cluster-dmz/kubeconfig \
  kubectl config view --merge --flatten \
  > ~/.kube/config.tmp && mv ~/.kube/config.tmp ~/.kube/config
```

Use **kubectx** or **k9s** for painless multi-cluster work.

---

### Cheat-sheet

| Action               | Command                                          |
| -------------------- | ------------------------------------------------ |
| See machines’ health | `talosctl health`                                |
| SSH-like shell       | `talosctl ssh -n <node>`                         |
| View logs            | `talosctl logs -n <node> -f`                     |
| Reboot a node        | `talosctl reboot -n <node>`                      |
| Upgrade Talos OS     | `talosctl upgrade --image ghcr.io/... -n <node>` |
