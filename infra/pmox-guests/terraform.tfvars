endpoint = "https://pve01:8006/api2/json"
lxcs = {
  "NETBIRD-GREG" = {
    start_on_boot       = true
    custom_conf_options = "lxc.cgroup2.devices.allow: c 10:200 rwm,lxc.mount.entry: /dev/net/tun dev/net/tun none bind,create=file"
    features            = { nesting = true }
    operating_system = {
      type = "ubuntu"
    }
    cpu    = { cores = 1 }
    memory = { dedicated = 512 }
    network_interface = {
      mac_address = "BC:24:11:63:AD:A1"
      vlan_id     = 20
    }
    node_name = "pve01"
    disk = { size = 8 }
  }

  "NETBIRD-FAM" = {
    start_on_boot       = true
    custom_conf_options = "lxc.cgroup2.devices.allow: c 10:200 rwm,lxc.mount.entry: /dev/net/tun dev/net/tun none bind,create=file"
    features            = { nesting = true }
    operating_system = {
      type = "ubuntu"
    }
    cpu    = { cores = 1 }
    memory = { dedicated = 512 }
    network_interface = {
      mac_address = "BC:24:11:AF:EB:5D"
      vlan_id     = 30
    }
    node_name = "pve02"
    disk = { size = 8 }
  }

  "NETBIRD-DMZ" = {
    start_on_boot       = true
    tags                = ["dmz"]
    custom_conf_options = "lxc.cgroup2.devices.allow: c 10:200 rwm,lxc.mount.entry: /dev/net/tun dev/net/tun none bind,create=file"
    features            = { nesting = true }
    operating_system = {
      type = "ubuntu"
    }
    cpu    = { cores = 1 }
    memory = { dedicated = 512 }
    network_interface = {
      mac_address = "BC:24:11:E6:58:5F"
      vlan_id     = 60
    }
    node_name = "pve03"
    disk = { size = 8 }
  }

  "DOCKER-INFRA" = {
    start_on_boot = true
    clone = {
      vm_id = 301
    }
    startup = {
      order = 99
    }
    cpu    = { cores = 1 }
    memory = { dedicated = 2048 }
    disk   = { size = 16 }
    mount_point = {
      "0" = {
        volume = "/mnt/pve/remote-hdd/template/iso"
        path   = "/mnt/iso_storage"
      }
    }
    network_interface = {
      mac_address = "BC:24:11:33:93:F8"
      vlan_id     = 10
    }
    node_name = "pve01"
  }

  "DOCKER-DMZ" = {
    start_on_boot = true
    tags          = ["dmz"]
    clone = {
      vm_id = 301
    }
    cpu    = { cores = 1 }
    memory = { dedicated = 4096 }
    network_interface = {
      mac_address = "BC:24:11:41:C6:77"
      vlan_id     = 60
    }
    disk = { size = 8 }
    node_name = "pve03"
  }

  "DDCLIENT" = {
    start_on_boot = true
    operating_system = {
      type = "ubuntu"
    }
    cpu    = { cores = 1 }
    memory = { dedicated = 256 }
    network_interface = {
      vlan_id = 10
    }
    disk = { size = 8 }
    node_name = "pve02"
  }
}