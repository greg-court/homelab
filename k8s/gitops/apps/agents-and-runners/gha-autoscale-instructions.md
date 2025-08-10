You’re 100% right: CPU-based HPA on the runner pods won’t scale when the *real* work is happening in BuildKit. The clean, 2025‑way to autoscale runners based on **actual GitHub job queue length** is to switch to **Actions Runner Controller (ARC) – Runner Scale Sets**. It’s the mainstream pattern now: ephemeral, per‑job pods; ARC talks to GitHub and scales up/down based on pending jobs. No more guessing with CPU.

Below is a drop‑in, Argo‑friendly setup you can apply to **all** your runners (docker / ansible / terraform). It keeps your BuildKit deployment exactly as-is.

---

# What you’ll end up with

* `actions-runner-controller` installed via Helm (CRDs + controller).
* A GitHub **App** (not a PAT) for runner auth.
* Three **Runner Scale Sets** (docker / ansible / terraform), each:

  * labels: `self-hosted,<tool>`
  * min/max runners (autoscaled by queue length)
  * your custom runner image (or swap to the official one later)
* Your existing **BuildKit** stays and autos-scales via HPA (as you already have).

---

# 0) One-off prerequisite (GitHub App)

Create a GitHub App (once) and put its credentials in Azure Key Vault (since you already use External Secrets):

* App permissions (repository scope):

  * **Actions: Read**
  * **Administration: Read & write** (needed to manage self-hosted runners)
  * **Checks: Read**
  * **Metadata: Read-only**
* Subscribe to events (optional but recommended): **workflow\_job**

Store these three items in Key Vault (use these exact key names so the ExternalSecret below works):

* `github-app-id` (numeric)
* `github-app-installation-id` (numeric)
* `github-app-private-key` (the PEM; include the full `-----BEGIN/END PRIVATE KEY-----` text)

---

# 1) Install ARC (controller) with Argo CD

**File: `k8s/gitops/clusters/trust/52-actions-runner-controller.yaml`**

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: actions-runner-controller
  namespace: argocd
  annotations: { argocd.argoproj.io/sync-wave: '15' }
spec:
  project: platform
  destination:
    server: https://kubernetes.default.svc
    namespace: actions-runner-system
  source:
    repoURL: https://actions-runner-controller.github.io/actions-runner-controller
    chart: actions-runner-controller
    targetRevision: 0.9.2 # or the latest stable
    helm:
      values: |
        # We provide GitHub App credentials via a Secret (External Secrets below),
        # so don't create an auth secret here.
        authSecret:
          create: false

        # Webhook server optional; not required for scale sets.
        githubWebhookServer:
          enabled: false
  syncPolicy:
    automated: { prune: true, selfHeal: true }
    syncOptions:
      - CreateNamespace=true
      - ServerSideApply=true
      - SkipDryRunOnMissingResource=true
```

---

# 2) Namespace + External Secret for the GitHub App

**File: `k8s/gitops/apps/gha-runners/namespace.yaml`**

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: actions-runner-system
  labels:
    pod-security.kubernetes.io/enforce: 'baseline'
```

**File: `k8s/gitops/apps/gha-runners/externalsecret-github-app.yaml`**

```yaml
apiVersion: external-secrets.io/v1
kind: ExternalSecret
metadata:
  name: github-app
  namespace: actions-runner-system
  annotations:
    argocd.argoproj.io/sync-wave: '-1'
spec:
  refreshInterval: 15m
  secretStoreRef:
    name: azure-kv-homelab
    kind: ClusterSecretStore
  target:
    name: github-app # <-- this is the Secret ARC expects below
  data:
    - secretKey: github_app_id
      remoteRef: { key: github-app-id }
    - secretKey: github_app_installation_id
      remoteRef: { key: github-app-installation-id }
    - secretKey: github_app_private_key
      remoteRef: { key: github-app-private-key }
```

> If you don’t want to keep the `gh-runners-env` PAT anymore, you can remove your old `externalsecrets-gh.yaml`. ARC with a GitHub App makes PATs unnecessary for runner registration.

---

# 3) Values for three Runner Scale Sets (docker / ansible / terraform)

Each of these files tells ARC to manage a scale set that auto‑scales by the **GitHub job queue** for your repo.

> If you want these runners available org‑wide, set `githubConfigUrl: https://github.com/<your-org>` and use labels accordingly. Right now I point them at your repo.

## Docker

**File: `k8s/gitops/apps/gha-runners/values-docker.yaml`**

```yaml
# Where to watch job queue
githubConfigUrl: https://github.com/greg-court/homelab
githubConfigSecret: github-app

runnerScaleSetName: gh-docker
minRunners: 0        # scale to zero when idle
maxRunners: 6        # bump as you like

# Labels must match your workflow "runs-on"
labels:
  - self-hosted
  - docker

# We use remote BuildKit, so no dind needed.
containerMode: "kubernetes"

template:
  spec:
    securityContext:
      fsGroup: 1000
    containers:
      - name: runner
        # Use your custom image (or switch to ghcr.io/actions/actions-runner and bake tools via initContainer)
        image: docker.io/gr10/gh-docker-runner:1.0.0
        env:
          - name: ACTIONS_RUNNER_PRINT_LOG_TO_STDOUT
            value: "true"
          - name: RUNNER_LABELS
            value: "self-hosted,docker"
        resources:
          requests:
            cpu: "250m"
            memory: "512Mi"
          limits:
            cpu: "2"
            memory: "2Gi"
```

## Ansible

**File: `k8s/gitops/apps/gha-runners/values-ansible.yaml`**

```yaml
githubConfigUrl: https://github.com/greg-court/homelab
githubConfigSecret: github-app

runnerScaleSetName: gh-ansible
minRunners: 0
maxRunners: 4

labels:
  - self-hosted
  - ansible

containerMode: "kubernetes"

template:
  spec:
    containers:
      - name: runner
        image: docker.io/gr10/gh-ansible-runner:2.0.0
        env:
          - name: ACTIONS_RUNNER_PRINT_LOG_TO_STDOUT
            value: "true"
          - name: RUNNER_LABELS
            value: "self-hosted,ansible"
        resources:
          requests:
            cpu: "200m"
            memory: "256Mi"
          limits:
            cpu: "2"
            memory: "2Gi"
```

## Terraform

**File: `k8s/gitops/apps/gha-runners/values-terraform.yaml`**

```yaml
githubConfigUrl: https://github.com/greg-court/homelab
githubConfigSecret: github-app

runnerScaleSetName: gh-terraform
minRunners: 0
maxRunners: 4

labels:
  - self-hosted
  - terraform

containerMode: "kubernetes"

template:
  spec:
    containers:
      - name: runner
        image: docker.io/gr10/gh-terraform-runner:1.0.0
        env:
          - name: ACTIONS_RUNNER_PRINT_LOG_TO_STDOUT
            value: "true"
          - name: RUNNER_LABELS
            value: "self-hosted,terraform"
        resources:
          requests:
            cpu: "200m"
            memory: "256Mi"
          limits:
            cpu: "2"
            memory: "2Gi"
```

---

# 4) Argo Apps for the three scale sets (Helm chart per set)

These install the `gha-runner-scale-set` chart three times, each with a values file above.

**File: `k8s/gitops/clusters/trust/61-gh-runners-docker.yaml`**

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: gh-runners-docker
  namespace: argocd
  annotations: { argocd.argoproj.io/sync-wave: '16' }
spec:
  project: platform
  destination: { server: https://kubernetes.default.svc, namespace: actions-runner-system }
  sources:
    - repoURL: https://actions-runner-controller.github.io/actions-runner-controller
      chart: gha-runner-scale-set
      targetRevision: 0.9.2 # or latest
      helm:
        valueFiles:
          - $values/k8s/gitops/apps/gha-runners/values-docker.yaml
    - repoURL: https://github.com/greg-court/homelab.git
      targetRevision: main
      ref: values
  syncPolicy:
    automated: { prune: true, selfHeal: true }
    syncOptions:
      - ServerSideApply=true
      - SkipDryRunOnMissingResource=true
```

**File: `k8s/gitops/clusters/trust/62-gh-runners-ansible.yaml`**

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: gh-runners-ansible
  namespace: argocd
  annotations: { argocd.argoproj.io/sync-wave: '16' }
spec:
  project: platform
  destination: { server: https://kubernetes.default.svc, namespace: actions-runner-system }
  sources:
    - repoURL: https://actions-runner-controller.github.io/actions-runner-controller
      chart: gha-runner-scale-set
      targetRevision: 0.9.2
      helm:
        valueFiles:
          - $values/k8s/gitops/apps/gha-runners/values-ansible.yaml
    - repoURL: https://github.com/greg-court/homelab.git
      targetRevision: main
      ref: values
  syncPolicy:
    automated: { prune: true, selfHeal: true }
    syncOptions:
      - ServerSideApply=true
      - SkipDryRunOnMissingResource=true
```

**File: `k8s/gitops/clusters/trust/63-gh-runners-terraform.yaml`**

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: gh-runners-terraform
  namespace: argocd
  annotations: { argocd.argoproj.io/sync-wave: '16' }
spec:
  project: platform
  destination: { server: https://kubernetes.default.svc, namespace: actions-runner-system }
  sources:
    - repoURL: https://actions-runner-controller.github.io/actions-runner-controller
      chart: gha-runner-scale-set
      targetRevision: 0.9.2
      helm:
        valueFiles:
          - $values/k8s/gitops/apps/gha-runners/values-terraform.yaml
    - repoURL: https://github.com/greg-court/homelab.git
      targetRevision: main
      ref: values
  syncPolicy:
    automated: { prune: true, selfHeal: true }
    syncOptions:
      - ServerSideApply=true
      - SkipDryRunOnMissingResource=true
```

> Note the **sync waves**: controller (15) → scale sets (16). That avoids CRD “not found” flapping.

---

# 5) Trim your old runner Deployments/HPAs (they’re obsolete now)

ARC creates **ephemeral pods per job**. Remove the static Deployments/HPAs for docker/ansible/terraform.

**Replace** your `k8s/gitops/apps/agents-and-runners/kustomization.yaml` with:

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - namespace.yaml
  - secretstore.yaml
  - externalsecrets-tfc.yaml        # keep if you still use TFC agent
  - configmap.yaml                  # optional; if unused, you can drop it
  - buildkit-config.yaml
  - buildkit-deployment.yaml
  - buildkit-service.yaml
  - buildkit-hpa.yaml
  - deployment-tfc.yaml

# removed:
# - externalsecrets-gh.yaml (not needed with GH App)
# - deployment-gh-docker.yaml
# - deployment-gh-terraform.yaml
# - deployment-gh-ansible.yaml
# - hpa.yaml
```

> Keep your **BuildKit** bits untouched; it’s still the remote builder all the runners will use.

---

# 6) Update your workflows (labels)

In your workflows, make sure the `runs-on` labels match the sets above, e.g.:

```yaml
runs-on: [self-hosted, docker]
# or [self-hosted, ansible]
# or [self-hosted, terraform]
```

That’s it. ARC will look at the **pending job queue for that repo** and spin up/down runner pods to match demand (within min/max). You’ll see:

```
kubectl get pods -n actions-runner-system
kubectl get runners -n actions-runner-system
kubectl logs -n actions-runner-system deploy/actions-runner-controller -f
```

---

## Notes & tips

* **Your images**: sticking with `docker.io/gr10/gh-*-runner:*` is fine if they retain the standard actions-runner entrypoint. If you prefer to track upstream, build your images FROM `ghcr.io/actions/actions-runner:<version>` and add your tools.
* **Remote BuildKit**: no change. The jobs will still call `docker/setup-buildx-action` with `endpoint: tcp://buildkitd.agents-and-runners.svc.cluster.local:1234`.
* **Scale-to-zero**: use `minRunners: 0` (already set).
* **Bigger bursts?** just raise `maxRunners`.
* **Org-wide**: set `githubConfigUrl` to `https://github.com/<org>` and put labels that your org workflows use.

If you want, I can also convert your **packer** runners to a scale set, but I kept that separate since you wired VIP/ports around it earlier. Want me to fold that into ARC too?
