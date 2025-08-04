# TRUST cluster

cd terraform/cluster-bootstraps/trust
terraform init
terraform apply -target=module.argocd.helm_release.argocd
terraform apply # create root-app, done

# DMZ cluster (same two-step)

cd ../dmz
terraform init
terraform apply -target=module.argocd.helm_release.argocd
terraform apply
