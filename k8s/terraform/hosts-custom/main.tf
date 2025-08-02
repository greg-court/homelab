module "proxmox_vms" {
  source              = "../../../tf-modules/proxmox-vms"
  vms                 = local.all_vms
  talos_templates_dir = "${path.module}/talos_config"
}
