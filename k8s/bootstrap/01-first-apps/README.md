rm -f ~/.kube/config # (optional)

KUBECONFIG=~/.kube/config:../00-talos-config/tmp/kubeconfig \
 kubectl config view --flatten --merge > ~/.kube/config.tmp \
 && mv ~/.kube/config.tmp ~/.kube/config
