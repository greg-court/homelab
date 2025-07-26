## Getting started

Check existing contexts with `talosctl config get-contexts`
If necessary, `rm ~/.talos/config` for a fresh start

---

## Generate config with custom install image

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

## Terraform apply at this stage

## First boot - mandatory first bootstrap (only need to bootstrap 1 control node)

```bash
talosctl config merge ./talosconfig # writes `~/.talos/config`
talosctl config endpoints k8s-ctrl-trust01.internal
talosctl config node k8s-ctrl-trust01.internal
talosctl bootstrap
```

```bash
cd ../cluster-dmz
talosctl config merge ./talosconfig # writes `~/.talos/config`
talosctl config endpoints k8s-ctrl-dmz01.internal
talosctl config node k8s-ctrl-dmz01.internal
talosctl bootstrap
```

## Managing the cluster

```bash
talosctl health
talosctl dashboard --nodes k8s-ctrl.internal
talosctl dashboard --nodes k8s-infra.internal
talosctl get services
```

## Create kubeconfig file (in cluster folder)

talosctl kubeconfig .

## Make kubeconfig your default

cp ./kubeconfig ~/.kube/config
