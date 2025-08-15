terraform {
  backend "azurerm" {
    subscription_id      = "f01a5d70-cf46-4291-80de-336ee2a894d4"
    resource_group_name  = "rg-homelab-uks"
    storage_account_name = "sthomelabuks"
    container_name       = "k8s"
    key                  = "homelab/talos-config.tfstate"
    use_azuread_auth     = true
  }

  required_providers {
    talos      = { source = "siderolabs/talos", version = ">= 0.6.0" }
    local      = { source = "hashicorp/local", version = ">= 2.4.0" }
    azurerm    = { source = "hashicorp/azurerm", version = ">= 3.100.0" }
    kubernetes = { source = "hashicorp/kubernetes", version = ">=2" }
    helm       = { source = "hashicorp/helm", version = ">=3" }
  }
}

provider "talos" {}
provider "azurerm" {
  features {}
  subscription_id = "f01a5d70-cf46-4291-80de-336ee2a894d4"
}

variable "kubeconfig_path" { default = "./tmp/kubeconfig" }

provider "kubernetes" { config_path = var.kubeconfig_path }
provider "helm" { kubernetes = { config_path = var.kubeconfig_path } }