# TRUST cluster

cd cluster-trust
terraform init
terraform apply -target=module.argocd.helm_release.argocd
terraform apply # create root-app, done

# DMZ cluster (same two-step)

cd ../cluster-dmz
terraform init
terraform apply -target=module.argocd.helm_release.argocd
terraform apply

# Get password

kubectl -n argocd get secret argocd-initial-admin-secret \
 -o jsonpath="{.data.password}" | base64 -d && echo
