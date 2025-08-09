endpoint           = "https://pve03:8006/api2/json"
ansible_public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINDJp/CC2LAbxlvjOWA9Op/mhtA0An/WLzb9cOYJT/r/ ansible-deploy-key"
lxcs = {
  "NETBIRD-GREG-01" = {
    start_on_boot       = true
    tags                = ["netbird"]
    custom_conf_options = "lxc.cgroup2.devices.allow: c 10:200 rwm,lxc.mount.entry: /dev/net/tun dev/net/tun none bind,create=file"
    features            = { nesting = true }
    operating_system = {
      type = "ubuntu"
    }
    cpu    = { cores = 1 }
    memory = { dedicated = 512 }
    network_interface = {
      mac_address = "BC:24:11:63:AD:A1"
      vlan_id     = 5
    }
    node_name = "pve03" # temp, change to pve01 later
    disk = {
      size         = 8
      datastore_id = "local-zfs"
    }
  }

  "NETBIRD-FAM-01" = {
    start_on_boot       = true
    tags                = ["netbird"]
    custom_conf_options = "lxc.cgroup2.devices.allow: c 10:200 rwm,lxc.mount.entry: /dev/net/tun dev/net/tun none bind,create=file"
    features            = { nesting = true }
    operating_system = {
      type = "ubuntu"
    }
    cpu    = { cores = 1 }
    memory = { dedicated = 512 }
    network_interface = {
      mac_address = "BC:24:11:AF:EB:5D"
      vlan_id     = 6
    }
    node_name = "pve03"
    disk = {
      size         = 8
      datastore_id = "local-zfs"
    }
  }

  "NETBIRD-DMZ-01" = {
    start_on_boot       = true
    tags                = ["dmz", "netbird"]
    custom_conf_options = "lxc.cgroup2.devices.allow: c 10:200 rwm,lxc.mount.entry: /dev/net/tun dev/net/tun none bind,create=file"
    features            = { nesting = true }
    operating_system = {
      type = "ubuntu"
    }
    cpu    = { cores = 1 }
    memory = { dedicated = 512 }
    network_interface = {
      mac_address = "BC:24:11:E6:58:5F"
      vlan_id     = 4
    }
    node_name = "pve03"
    disk = {
      size         = 8
      datastore_id = "local-zfs"
    }
  }

  "ADGUARD-DNS-01" = {
    start_on_boot = true
    operating_system = {
      type = "ubuntu"
    }
    cpu    = { cores = 1 }
    memory = { dedicated = 512 }
    network_interface = {
      mac_address = "BC:24:11:7B:EA:3E"
      vlan_id     = 3
    }
    disk = {
      size         = 16
      datastore_id = "local-zfs"
    }
    node_name = "pve03"
  }

  "ADGUARD-DNS-02" = {
    start_on_boot = true
    tags          = ["adguard"]
    operating_system = {
      type = "ubuntu"
    }
    cpu    = { cores = 1 }
    memory = { dedicated = 512 }
    network_interface = {
      mac_address = "BC:24:11:E7:80:82"
      vlan_id     = 3
    }
    disk = {
      size         = 16
      datastore_id = "local-zfs"
    }
    node_name = "pve03"
  }

  "ADGUARD-DNS-03" = {
    start_on_boot = true
    tags          = ["adguard"]
    operating_system = {
      type = "ubuntu"
    }
    cpu    = { cores = 1 }
    memory = { dedicated = 512 }
    network_interface = {
      mac_address = "BC:24:11:7F:1C:BD"
      vlan_id     = 3
    }
    disk = {
      size         = 16
      datastore_id = "local-zfs"
    }
    node_name = "pve03"
  }
}