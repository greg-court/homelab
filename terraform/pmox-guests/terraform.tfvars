endpoint = "https://pve02:8006/api2/json"
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
    disk = {
      size         = 8
      datastore_id = "remote-nfs"
    }
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
    disk = {
      size         = 8
      datastore_id = "remote-nfs"
    }
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
    disk = {
      size         = 8
      datastore_id = "remote-nfs"
    }
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
    disk = {
      size         = 8
      datastore_id = "remote-nfs"
    }
    node_name = "pve02"
  }

  "ADGUARD-DNS" = {
    start_on_boot = true
    startup       = { order = 2 }
    operating_system = {
      type = "ubuntu"
    }
    cpu    = { cores = 1 }
    memory = { dedicated = 1024 }
    network_interface = {
      mac_address = "BC:24:11:E7:80:82"
      vlan_id     = 10
    }
    disk = {
      size         = 16
      datastore_id = "remote-nfs"
    }
    node_name = "pve02"
  }

  "DNS-TRAINER" = {
    start_on_boot = true
    cpu           = { cores = 1 }
    clone = {
      vm_id = 300
    }
    memory = { dedicated = 256 }
    network_interface = {
      vlan_id = 10
    }
    disk = {
      size         = 8
      datastore_id = "remote-nfs"
    }
    node_name = "pve01"
  }

  "DOCKER-DMZ" = { # to be deleted
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
    disk      = { size = 8 }
    node_name = "pve03"
  }
}