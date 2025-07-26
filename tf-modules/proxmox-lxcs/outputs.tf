output "ids" {
  description = "Map of container name to service ID"
  value = {
    for name, config in local.processed_lxc_containers :
    name => proxmox_virtual_environment_container.fleet[name].id
  }
}