lxcs = {
  "NETBIRD-TEST" = {
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
    disk = {
      size         = 8
      datastore_id = "local-zfs"
    }
  }
}