terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 3"
    }
  }
}

provider "kubernetes" {
  config_path = "../hosts/configs/cluster-dmz/kubeconfig"
}

provider "helm" {
  kubernetes = {
    config_path = "../hosts/configs/cluster-dmz/kubeconfig"
  }
}