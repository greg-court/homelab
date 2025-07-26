terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = ">= 0.80"
    }
    utils = {
      source  = "cloudposse/utils"
      version = ">= 1.30"
    }
  }
}