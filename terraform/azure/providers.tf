terraform {
  required_providers {
    azurerm = { source = "hashicorp/azurerm", version = ">= 4.0" }
    azuread = { source = "hashicorp/azuread", version = ">=3.0" }
  }
  backend "azurerm" {
    subscription_id      = "f01a5d70-cf46-4291-80de-336ee2a894d4"
    resource_group_name  = "rg-homelab-uks"
    storage_account_name = "sthomelabuks"
    container_name       = "tfstate"
    key                  = "azure.tfstate"
    use_azuread_auth     = true
  }
}

variable "subscription_id" {}
provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}

provider "azuread" {}
data "azurerm_client_config" "current" {}
