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

# Advanced troubleshooting - Checking the audiences

NS=argocd
POD=$(kubectl -n $NS get pods \
      -l app.kubernetes.io/name=argocd-application-controller \
      -o jsonpath='{.items[0].metadata.name}')
TOKEN=$(kubectl -n $NS exec "$POD" -- \
 cat /var/run/secrets/kubernetes.io/serviceaccount/token | tr -d '\n')
python3 - <<PY
import base64, json, textwrap
t = """$TOKEN"""
payload = t.split('.')[1]
data = json.loads(base64.urlsafe_b64decode(payload + '=='))
print("\nToken audiences:\n", textwrap.indent(json.dumps(data['aud'], indent=2), " "))
PY
kubectl -n kube-system get pod -l component=kube-apiserver \
 -o jsonpath='{.items[0].spec.containers[0].command}' | tr ',' '\n' |
grep -- --api-audiences

## Logs

kubectl logs -n argocd argocd-application-controller-0 -f
