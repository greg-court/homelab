data "utils_deep_merge_yaml" "talos_config" {
  for_each = {
    for name, config in var.vms : name => config
    if lookup(config, "talos", null) != null
  }

  input = [
    file("${var.talos_templates_dir}/${each.value.talos.cluster}/${each.value.talos.type}.yaml"),
    lookup(each.value.talos, "patch_data", "{}")
  ]
}

resource "proxmox_virtual_environment_file" "talos_snippet" {
  for_each = {
    for name, config in var.vms :
    name => {
      node_name = config.node_name
      cluster   = config.talos.cluster
      type      = config.talos.type
      patch     = config.talos.patch_data
    }
    if lookup(config, "talos", null) != null
  }
  content_type = "snippets"
  datastore_id = "remote-hdd"
  node_name    = each.value.node_name

  source_raw {
    file_name = "${lower(each.key)}-talos.yaml"
    # data      = sensitive(each.value.output)
    data = data.utils_deep_merge_yaml.talos_config[each.key].output
  }
}