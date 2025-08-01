terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = ">= 0.80"
    }
  }
  # backend "azurerm" {
  #   subscription_id      = "f01a5d70-cf46-4291-80de-336ee2a894d4"
  #   resource_group_name  = "rg-homelab-uks-01"
  #   storage_account_name = "sthomelabuks01"
  #   container_name       = "proxmox-tfstate"
  #   key                  = "guests.tfstate"
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