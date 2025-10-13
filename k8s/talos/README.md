# Initialisation

```bash
# note, this process must be initiated from the INFRA vlan due to asymmetric routing

cd /Users/gregc/devSandbox/github/homelab/k8s/talos
sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder

nc -vz n1.klab.internal 50000
nc -vz n2.klab.internal 50000
nc -vz n3.klab.internal 50000

terraform apply --auto-approve
# after first failure, enable LACP on switches
terraform apply --auto-approve

rm -f ~/.talos/config && rm -f ~/.kube/config
talosctl config merge ./cluster-configs/talosconfig

talosctl config use-context klab
talosctl config node api.klab.internal
talosctl config endpoints api.klab.internal

KUBECONFIG=~/.kube/config:cluster-configs/kubeconfig kubectl config view --flatten --merge > ~/.kube/config.tmp && mv ~/.kube/config.tmp ~/.kube/config

talosctl health

kubectl -n argocd get secret argocd-initial-admin-secret \
 -o jsonpath="{.data.password}" | base64 -d; echo

################################################################################

kubectl -n argocd port-forward svc/argocd-server 6969:443

kubectl get secret -n monitoring kube-prometheus-stack-grafana \
-o jsonpath="{.data.admin-password}" | base64 -d; echo
```

# Nuking / resetting

```bash
cd /Users/gregc/devSandbox/github/homelab/k8s/talos
terraform state rm 'helm_release.cilium'
terraform state rm 'helm_release.argocd'
terraform state rm 'helm_release.argocd_root_apps'
terraform state rm 'kubernetes_namespace.argocd'
terraform state rm 'kubernetes_namespace.external_secrets'
terraform state rm 'kubernetes_secret.azure_kv_creds'

terraform destroy --auto-approve

talosctl reset \
  --graceful=false \
  --reboot \
  --system-labels-to-wipe STATE \
  --system-labels-to-wipe EPHEMERAL \
  -e n1.klab.internal,n2.klab.internal,n3.klab.internal \
  -n n1.klab.internal,n2.klab.internal,n3.klab.internal
```
