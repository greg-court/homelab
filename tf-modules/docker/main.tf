data "docker_registry_image" "img" {
  for_each = { for k in local.active_container_types : k => local.container_definitions[k].image }
  name     = each.value
}

resource "docker_image" "image" {
  for_each      = { for k in local.active_container_types : k => local.container_definitions[k].image }
  name          = each.value
  pull_triggers = [data.docker_registry_image.img[each.key].sha256_digest]
}

resource "docker_container" "this" {
  for_each = local.all_instances

  name    = each.value.instance_name
  image   = docker_image.image[each.value.container_type].image_id
  command = each.value.command

  network_mode = try(each.value.network_mode, null)
  group_add    = try(each.value.group_add, null)
  env          = each.value.env_final

  dynamic "volumes" {
    for_each = each.value.volumes
    content {
      host_path      = volumes.value.host_path
      container_path = volumes.value.container_path
      read_only      = try(volumes.value.read_only, null)
    }
  }

  dynamic "mounts" {
    for_each = each.value.mounts
    content {
      type      = mounts.value.type
      source    = mounts.value.source
      target    = mounts.value.target
      read_only = mounts.value.read_only
    }
  }

  dynamic "ports" {
    for_each = each.value.ports
    content {
      internal = ports.value.internal
      external = try(ports.value.external, each.value.instance_cfg.external_port, null) # Null omits → random if block present, but with ports=[] defaults, no block
    }
  }

  dynamic "labels" {
    for_each = each.value.labels
    content {
      label = labels.key
      value = labels.value
    }
  }

  dynamic "capabilities" {
    for_each = try(each.value.capabilities != null ? [each.value.capabilities] : [], [])
    content {
      add  = try(capabilities.value.add, null)
      drop = try(capabilities.value.drop, null)
    }
  }

  restart = "always"

  lifecycle {
    replace_triggered_by = [terraform_data.replace_triggers[each.key]]
  }
}

resource "terraform_data" "replace_triggers" {
  # one record for every container instance
  for_each = local.all_instances # keys like "traefik.traefik"

  input = (
    contains(keys(var.replace_dirs), each.key)
    ? md5(join("\n", [
      for f in sort(fileset(var.replace_dirs[each.key], "**/*")) :
      "${f}:${filemd5("${var.replace_dirs[each.key]}/${f}")}"
    ]))
    : "" # no dir to watch → constant
  )
}