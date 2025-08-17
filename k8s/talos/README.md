# Initialisation

rm -f ~/.talos/config && rm -f ~/.kube/config
talosctl config merge ./tmp/talosconfig

talosctl config use-context klab
talosctl config node api.klab.internal
talosctl config endpoints api.klab.internal
talosctl health

KUBECONFIG=~/.kube/config:tmp/kubeconfig kubectl config view --flatten --merge > ~/.kube/config.tmp && mv ~/.kube/config.tmp ~/.kube/config

kubectl -n argocd get secret argocd-initial-admin-secret \
 -o jsonpath="{.data.password}" | base64 -d; echo
kubectl -n argocd port-forward svc/argocd-server 6969:443

# Nuking / resetting

terraform destroy --auto-approve

talosctl reset \
 --system-labels-to-wipe EPHEMERAL,STATE \
 --graceful=false \
 --reboot \
 -e n1.klab.internal -n n1.klab.internal
