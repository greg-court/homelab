terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = ">= 0.80"
    }
  }
}

provider "proxmox" {
  endpoint = var.endpoint
  username = "root@pam"
  password = var.root_password
  insecure = true
}