data "utils_deep_merge_yaml" "talos_config" {
  for_each = {
    for name, config in var.vms : name => config
    if lookup(config, "talos", null) != null
  }

  input = [
    file("${var.talos_templates_dir}/${each.value.talos.type}.yaml"),
    lookup(each.value.talos, "patch_data", "{}")
  ]
}

resource "proxmox_virtual_environment_file" "talos_snippet" {
  for_each     = data.utils_deep_merge_yaml.talos_config
  content_type = "snippets"
  datastore_id = "local"
  node_name    = "pve"

  source_raw {
    file_name = "${lower(each.key)}-talos.yaml"
    # data      = sensitive(each.value.output)
    data      = each.value.output
  }
}