terraform {
  required_providers {
    azurerm = { source = "hashicorp/azurerm", version = ">= 4.0" }
    azuread = { source = "hashicorp/azuread", version = ">=3.0" }
  }
}

variable "subscription_id" {}
provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}

provider "azuread" {}
data "azurerm_client_config" "current" {}
