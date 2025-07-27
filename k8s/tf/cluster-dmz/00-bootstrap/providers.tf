terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2"
    }
  }
}

provider "kubernetes" {
  config_path = "../kubeconfig"
}

provider "helm" {
  kubernetes {
    config_path = "../kubeconfig"
  }
}