terraform {
  backend "azurerm" {
    subscription_id      = "f01a5d70-cf46-4291-80de-336ee2a894d4"
    resource_group_name  = "rg-homelab-uks"
    storage_account_name = "sthomelabuks"
    container_name       = "k8s"
    key                  = "homelab/first-apps.tfstate"
    use_azuread_auth     = true
  }

  required_providers {
    helm       = { source = "hashicorp/helm", version = ">= 3" }
    kubernetes = { source = "hashicorp/kubernetes", version = ">= 2" }
  }
}

variable "cluster_name" { default = "homelab" }
variable "kubeconfig_path" { default = "../${path.module}/tmp/kubeconfig" }

provider "kubernetes" { config_path = var.kubeconfig_path }
provider "helm" { kubernetes = { config_path = var.kubeconfig_path } }