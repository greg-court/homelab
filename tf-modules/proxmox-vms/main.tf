locals {
  common_boot_disk = {
    interface = "scsi0"
    cache     = "writeback"
    discard   = "on"
    iothread  = true
    ssd       = true
  }

  # This local processes the input from the .tfvars file
  # It intelligently merges the common boot disk properties into each VM's disk config.
  processed_vms = {
    for name, config in nonsensitive(var.vms) : name => merge(config, {
      disks = {
        for key, disk_config in config.disks : key => merge(
          # For scsi0 disks, merge the common settings. For others, don't.
          key == "scsi0" ? local.common_boot_disk : {},
          disk_config
        )
      }
    })
  }
}

resource "proxmox_virtual_environment_vm" "fleet" {
  for_each = local.processed_vms

  name                = each.key
  node_name           = lookup(each.value, "node_name", null)
  on_boot             = each.value.on_boot
  bios                = each.value.bios
  vm_id               = lookup(each.value, "vm_id", null)
  description         = lookup(each.value, "description", null)
  tags                = lookup(each.value, "tags", [])
  protection          = lookup(each.value, "protection", false)
  scsi_hardware       = lookup(each.value, "scsi_hardware", "virtio-scsi-single")
  machine             = lookup(each.value, "machine", "pc-q35-9.2+pve1")
  hook_script_file_id = lookup(each.value, "hook_script_file_id", null)
  boot_order          = lookup(each.value, "boot_order", [])
  keyboard_layout     = "en-us"

  agent {
    enabled = try(each.value.agent, false)
    type    = "virtio"
  }

  cpu {
    cores   = each.value.cpu.cores
    flags   = null
    type    = lookup(each.value.cpu, "type", "host")
    sockets = lookup(each.value.cpu, "sockets", 1)
  }

  memory {
    dedicated = each.value.memory.dedicated
  }

  operating_system {
    type = each.value.operating_system.type
  }

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

  dynamic "efi_disk" {
    for_each = lookup(each.value, "efi_disk", null) != null ? [each.value.efi_disk] : []
    content {
      file_format       = lookup(efi_disk.value, "file_format", "raw")
      datastore_id      = lookup(efi_disk.value, "datastore_id", "local-zfs")
      type              = lookup(efi_disk.value, "type", "4m")
      pre_enrolled_keys = lookup(efi_disk.value, "pre_enrolled_keys", true)
    }
  }

  dynamic "tpm_state" {
    for_each = lookup(each.value, "tpm_state", null) != null ? [each.value.tpm_state] : []
    content {
      datastore_id = lookup(tpm_state.value, "datastore_id", "local-zfs")
      version      = lookup(tpm_state.value, "version", "v2.0")
    }
  }

  dynamic "network_device" {
    for_each = { for i, nd in lookup(each.value, "network_devices", []) : i => nd }
    content {
      model       = lookup(network_device.value, "model", "virtio")
      bridge      = lookup(network_device.value, "bridge", "vmbr0")
      mac_address = lookup(network_device.value, "mac_address", null)
      firewall    = lookup(network_device.value, "firewall", true)
      vlan_id     = lookup(network_device.value, "vlan_id", null)
    }
  }

  dynamic "initialization" {
    for_each = lookup(each.value, "initialization", null) != null ? [each.value.initialization] : []

    content {
      datastore_id      = lookup(initialization.value, "datastore_id", "local-zfs")
      user_data_file_id = lookup(initialization.value, "user_data_file_id", null)
      dynamic "ip_config" {
        for_each = [lookup(initialization.value, "ip_config", {})]
        content {
          dynamic "ipv4" {
            for_each = [lookup(ip_config.value, "ipv4", { address = "dhcp" })]
            content {
              address = ipv4.value.address
              gateway = lookup(ipv4.value, "gateway", null)
            }
          }
          dynamic "ipv6" {
            for_each = lookup(ip_config.value, "ipv6", null) != null ? [ip_config.value.ipv6] : []
            content {
              address = lookup(ipv6.value, "address", null)
              gateway = lookup(ipv6.value, "gateway", null)
            }
          }
        }
      }
    }
  }

  dynamic "initialization" {
    for_each = lookup(each.value, "talos", null) != null ? [1] : []

    content {
      datastore_id      = "local-zfs"
      user_data_file_id = proxmox_virtual_environment_file.talos_snippet[each.key].id

      ip_config {
        ipv4 {
          address = "dhcp" # Talos will override if static in config
        }
      }
    }
  }

  dynamic "disk" {
    for_each = lookup(each.value, "disks", {})
    content {
      interface         = disk.key
      datastore_id      = lookup(disk.value, "datastore_id", "local-zfs")
      size              = lookup(disk.value, "size", null)
      cache             = lookup(disk.value, "cache", null)
      discard           = lookup(disk.value, "discard", null)
      iothread          = lookup(disk.value, "iothread", null)
      ssd               = lookup(disk.value, "ssd", null)
      replicate         = lookup(disk.value, "replicate", null)
      path_in_datastore = lookup(disk.value, "path_in_datastore", null)
      file_id           = lookup(disk.value, "file_id", null)
    }
  }

  dynamic "clone" {
    for_each = lookup(each.value, "clone", null) != null ? [each.value.clone] : []
    content {
      vm_id        = clone.value.vm_id
      full         = lookup(clone.value, "full", true)
      datastore_id = lookup(clone.value, "datastore_id", "local-zfs")
      node_name    = lookup(clone.value, "node_name", each.value.node_name)
    }
  }

  dynamic "cdrom" {
    for_each = lookup(each.value, "cdrom", null) != null ? [each.value.cdrom] : []

    content {
      enabled = true
      file_id = cdrom.value.file_id
    }
  }

  lifecycle {
    ignore_changes = [
      timeout_clone,
      timeout_create,
      timeout_migrate,
      timeout_reboot,
      timeout_shutdown_vm,
      timeout_start_vm,
      timeout_stop_vm,
      started,
      hostpci,
      cdrom[0].enabled
    ]
  }
}