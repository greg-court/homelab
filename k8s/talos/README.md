rm -f ~/.talos/config && rm -f ~/.kube/config
talosctl config merge ./tmp/talosconfig

talosctl config use-context klab
talosctl config node api.klab.internal
talosctl config endpoints api.klab.internal
talosctl health

KUBECONFIG=~/.kube/config:tmp/kubeconfig kubectl config view --flatten --merge > ~/.kube/config.tmp && mv ~/.kube/config.tmp ~/.kube/config
