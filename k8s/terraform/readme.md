# TRUST cluster

cd cluster-trust
terraform init
terraform apply -target=module.argocd.helm_release.argocd --auto-approve
terraform apply --auto-approve # create root-app, done
kubectx admin@cluster-trust
kubectl -n argocd get secret argocd-initial-admin-secret \
 -o jsonpath="{.data.password}" | base64 -d && echo
kubectl -n argocd port-forward svc/argocd-server 8080:443

# DMZ cluster (same two-step)

cd ../cluster-dmz
terraform init
terraform apply -target=module.argocd.helm_release.argocd --auto-approve
terraform apply --auto-approve
kubectx admin@cluster-dmz
kubectl -n argocd get secret argocd-initial-admin-secret \
 -o jsonpath="{.data.password}" | base64 -d && echo
kubectl -n argocd port-forward svc/argocd-server 8080:443

# Troubleshooting

## Permissions

kubectl get clusterrolebinding argocd-application-controller-admin -o yaml
kubectl get clusterrole argocd-application-controller -o yaml
kubectl describe clusterrole argocd-application-controller
kubectl get clusterrolebinding -o wide | grep argocd-application-controller
kubectl get rolebinding -n argocd -o wide | grep argocd-application-controller
SA=system:serviceaccount:argocd:argocd-application-controller
kubectl auth can-i --as=$SA --list

## Check Configuration

helm get values argocd -n argocd --all > argocd.txt
kubectl -n argocd get secret argocd-secret -o yaml

## Check tokens

kubectl -n argocd exec -it argocd-application-controller-0 -- \
 ls -l /var/run/secrets/kubernetes.io/serviceaccount
kubectl -n argocd exec -it argocd-application-controller-0 -- \
 cat /var/run/secrets/kubernetes.io/serviceaccount/token

## Logs

kubectl logs -n argocd argocd-application-controller-0 -f
