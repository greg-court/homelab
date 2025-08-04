# TRUST cluster

cd cluster-trust
terraform init
terraform apply -target=module.argocd.helm_release.argocd --auto-approve
terraform apply --auto-approve # create root-app, done
kubectx admin@cluster-trust
kubectl -n argocd port-forward svc/argocd-server 8080:443

# DMZ cluster (same two-step)

cd ../cluster-dmz
terraform init
terraform apply -target=module.argocd.helm_release.argocd --auto-approve
terraform apply --auto-approve
kubectx admin@cluster-dmz
kubectl -n argocd port-forward svc/argocd-server 8080:443

# Get password

kubectl -n argocd get secret argocd-initial-admin-secret \
 -o jsonpath="{.data.password}" | base64 -d && echo
