🔧 Split the Concerns: Use the Right Tool for the Right Layer

1. Terraform = Provisioning Infrastructure (Outside Kubernetes)
   Use it to provision EKS, IAM roles, VPCs, DBs, SQS, Secrets Manager, etc.
   Can bootstrap Kubernetes tools like ArgoCD or FluxCD via Terraform (once and done).
   Avoid using it to manage Kubernetes resources (e.g., Deployment, Service, etc.) — it leads to state conflicts and poor diffs.
2. GitOps Tools (ArgoCD / Flux) = Application & Kubernetes Resource Management
   Reconcile your apps from Git, declaratively.
   Works well with Helm, Kustomize, plain YAML.
   Continuous reconciliation → self-healing, easy rollback, better visibility.
   Better lifecycle management (diffs, sync waves, app-of-apps pattern, etc.)
