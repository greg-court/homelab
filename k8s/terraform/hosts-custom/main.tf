module "proxmox_vms" {
  source              = "../../../tf-modules/proxmox-vms"
  vms                 = var.hosts
  talos_templates_dir = "${path.module}/talos_config"
}