# --- Use this block to move from old to new LXC names ---
# moved {
#   from = proxmox_virtual_environment_container.fleet["OLD-NAME"]
#   to   = proxmox_virtual_environment_container.fleet["NEW-NAME"]
# }

locals {
  os_templates = {
    ubuntu = "local:vztmpl/ubuntu-24.04-standard_24.04-2_amd64.tar.zst"
    debian = "local:vztmpl/debian-12-standard_12.7-1_amd64.tar.zst"
  }

  vlan_to_nameserver_map = {
    "0"  = "192.168.0.1", "10" = "192.168.1.1", "20" = "192.168.2.1", "30" = "192.168.3.1"
    "40" = "192.168.4.1", "50" = "192.168.5.1", "60" = "192.168.6.1", "70" = "192.168.7.1"
  }

  processed_lxc_containers = {
    for name, config in nonsensitive(var.lxcs) : name => merge(
      config,
      # It checks if a 'clone' block exists.
      lookup(config, "clone", null) == null ? {
        # IF NOT a clone, then add the template_file_id to the OS block.
        operating_system = merge(
          lookup(config, "operating_system", {}),
          { "template_file_id" = local.os_templates[config.operating_system.type] }
        )
      } : {} # ELSE (if it IS a clone), do nothing.
    )
  }
}

resource "proxmox_virtual_environment_container" "fleet" {
  for_each = local.processed_lxc_containers

  hook_script_file_id = lookup(each.value, "hook_script_file_id", null)

  node_name    = lookup(each.value, "node_name", null)
  description  = lookup(each.value, "description", null)
  tags         = lookup(each.value, "tags", null)
  template     = lookup(each.value, "template", false)
  unprivileged = lookup(each.value, "unprivileged", true)
  protection   = lookup(each.value, "protection", false)

  start_on_boot = lookup(each.value, "start_on_boot", false)

  dynamic "startup" {
    for_each = [
      merge(
        {
          order      = 10
          up_delay   = null
          down_delay = null
        },
        lookup(each.value, "startup", {})
      )
    ]

    content {
      order      = startup.value.order
      up_delay   = startup.value.up_delay
      down_delay = startup.value.down_delay
    }
  }

  dynamic "operating_system" {
    for_each = lookup(each.value, "clone", null) == null ? [each.value.operating_system] : []
    content {
      template_file_id = operating_system.value.template_file_id
      type             = operating_system.value.type
    }
  }

  cpu {
    architecture = lookup(try(each.value.cpu, {}), "architecture", "amd64")
    cores        = lookup(try(each.value.cpu, {}), "cores", 1)
  }

  disk {
    datastore_id = lookup(try(each.value.disk, {}), "datastore_id", "local-zfs")
    size         = each.value.disk.size
  }

  features {
    nesting = lookup(try(each.value.features, {}), "nesting", true)
    keyctl  = lookup(try(each.value.features, {}), "keyctl", null)
    fuse    = lookup(try(each.value.features, {}), "fuse", null)
  }

  initialization {
    hostname = each.key

    ip_config {
      ipv4 {
        address = "dhcp"
      }
    }

    dns {
      domain = lookup(try(each.value.dns, {}), "domain", null)
      servers = [
        lookup(
          local.vlan_to_nameserver_map,
          tostring(lookup(try(each.value.network_interface, {}), "vlan_id", 0)),
          null
        )
      ]
    }
  }

  memory {
    dedicated = lookup(try(each.value.memory, {}), "dedicated", 512)
    swap      = lookup(try(each.value.memory, {}), "swap", lookup(try(each.value.memory, {}), "dedicated", 512)) # deliberately matching dedicated
  }

  dynamic "mount_point" {
    for_each = try(each.value.mount_point, {})
    content {
      path   = mount_point.value.path
      volume = mount_point.value.volume
    }
  }

  network_interface {
    name        = "eth0"
    bridge      = "vmbr0"
    firewall    = true
    mac_address = lookup(try(each.value.network_interface, {}), "mac_address", null)
    vlan_id     = lookup(try(each.value.network_interface, {}), "vlan_id", null)
  }

  dynamic "clone" {
    for_each = lookup(each.value, "clone", null) != null ? [each.value.clone] : []
    content {
      vm_id        = clone.value.vm_id
      datastore_id = lookup(clone.value, "datastore_id", "local-zfs")
      node_name    = lookup(clone.value, "node_name", each.value.node_name)
    }
  }

  lifecycle {
    ignore_changes = [
      operating_system[0].template_file_id,
      started,
      clone,
      operating_system
    ]
  }
}