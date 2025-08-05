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

kubectl get clusterrolebinding argocd-application-controller-admin -o yaml
kubectl get clusterrole argocd-application-controller -o yaml
kubectl describe clusterrole argocd-application-controller
kubectl get clusterrolebinding -o wide | grep argocd-application-controller
kubectl get rolebinding -n argocd -o wide | grep argocd-application-controller
SA=system:serviceaccount:argocd:argocd-application-controller
kubectl auth can-i --as=$SA --list
