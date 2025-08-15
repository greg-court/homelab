cluster_name         = "klab"
cluster_endpoint     = "https://api.klab.internal:6443"
bootstrap_node       = "n1.klab.internal"
api_server           = "api.klab.internal"
install_disk         = "/dev/sda"
storage_account_name = "sthomelabuks"
container_name       = "k8s"

bootstrap = "false"

bootstrap_repo_url  = "https://github.com/greg-court/homelab.git"
bootstrap_repo_path = "k8s/gitops/clusters/homelab"