terraform {
  required_providers {
    proxmox    = { source = "bpg/proxmox", version = ">= 0.80" }
    talos      = { source = "siderolabs/talos", version = ">= 0.6.0" }
    helm       = { source = "hashicorp/helm", version = ">=3" }
    kubernetes = { source = "hashicorp/kubernetes", version = ">=2" }
  }
  # backend "azurerm" {
  #   subscription_id      = "f01a5d70-cf46-4291-80de-336ee2a894d4"
  #   resource_group_name  = "rg-homelab-uks-01"
  #   storage_account_name = "sthomelabuks01"
  #   container_name       = "kubernetes-tfstate"
  #   key                  = "talos-hosts.tfstate"
  #   use_azuread_auth     = true
  # }
}

# provider "proxmox" {
#   endpoint  = var.endpoint
#   api_token = var.api_token
#   insecure  = true
# }

variable "root_password" { type = string }
provider "proxmox" {
  endpoint = var.endpoint
  username = "root@pam"
  password = var.root_password
  insecure = true
}

provider "talos" {}

provider "helm" {
  alias = "trust"
  kubernetes = {
    config_path = "${path.module}/configs/cluster-trust/kubeconfig"
  }
}

provider "helm" {
  alias = "dmz"
  kubernetes = {
    config_path = "${path.module}/configs/cluster-dmz/kubeconfig"
  }
}

provider "kubernetes" {
  alias       = "trust"
  config_path = "${path.module}/configs/cluster-trust/kubeconfig"
}

provider "kubernetes" {
  alias       = "dmz"
  config_path = "${path.module}/configs/cluster-dmz/kubeconfig"
}
