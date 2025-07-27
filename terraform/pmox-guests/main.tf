module "lxcs" {
  source = "../../tf-modules/proxmox-lxcs"
  lxcs   = var.lxcs
}