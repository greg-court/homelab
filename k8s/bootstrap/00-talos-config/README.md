rm -f ~/.talos/config # (optional)

# Phase 1: render secrets & configs (no bootstrap yet)

terraform init -reconfigure
terraform apply

# Apply SAME machine config to all 3 nodes (after ISO boot)

talosctl -n h1.klab.internal apply-config --insecure -f ./tmp/controlplane.yaml
talosctl -n h2.klab.internal apply-config --insecure -f ./tmp/controlplane.yaml
talosctl -n h3.klab.internal apply-config --insecure -f ./tmp/controlplane.yaml

# Phase 2: bootstrap & fetch kubeconfig (Talos provider)

terraform apply -var='bootstrap=true'

# Kubeconfig is now at:

./tmp/kubeconfig
