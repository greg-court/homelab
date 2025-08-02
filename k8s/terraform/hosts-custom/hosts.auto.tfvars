hosts = {
  "K8S-TRUST-01" = {
    tags             = ["talos"]
    on_boot          = true
    agent            = true
    bios             = "seabios"
    cpu              = { cores = 2 }
    memory           = { dedicated = 4096 }
    operating_system = { type = "l26" }
    network_devices  = [{ vlan_id = 3, mac_address = "BC:24:11:D2:72:43" }]
    disks = {
      "scsi0" = { size = 16 }
    }
    cdrom = {
      file_id = "remote-hdd:iso/talos-nocloud-amd64-qemu.iso"
    }
    talos = {
      cluster = "cluster-trust"
      type    = "controlplane"
      patch_data = <<EOF
machine:
  network:
    hostname: k8s-trust-01.internal
  nodeLabels:
    zone: infra
EOF
    }
    node_name = "pve01"
  }

  "K8S-TRUST-02" = {
    tags             = ["talos"]
    on_boot          = true
    agent            = true
    bios             = "seabios"
    cpu              = { cores = 2 }
    memory           = { dedicated = 4096 }
    operating_system = { type = "l26" }
    network_devices  = [{ vlan_id = 3, mac_address = "BC:24:11:E2:67:FD" }]
    disks = {
      "scsi0" = { size = 16 }
    }
    cdrom = {
      file_id = "remote-hdd:iso/talos-nocloud-amd64-qemu.iso"
    }
    talos = {
      cluster = "cluster-trust"
      type    = "controlplane"
      patch_data = <<EOF
machine:
  network:
    hostname: k8s-trust-02.internal
  nodeLabels:
    zone: infra
EOF
    }
    node_name = "pve02"
  }

  "K8S-TRUST-03" = {
    tags             = ["talos"]
    on_boot          = true
    agent            = true
    bios             = "seabios"
    cpu              = { cores = 2 }
    memory           = { dedicated = 4096 }
    operating_system = { type = "l26" }
    network_devices  = [{ vlan_id = 3, mac_address = "BC:24:11:CC:92:00" }]
    disks = {
      "scsi0" = { size = 16 }
    }
    cdrom = {
      file_id = "remote-hdd:iso/talos-nocloud-amd64-qemu.iso"
    }
    talos = {
      cluster = "cluster-trust"
      type    = "controlplane"
      patch_data = <<EOF
machine:
  network:
    hostname: k8s-trust-03.internal
  nodeLabels:
    zone: infra
EOF
    }
    node_name = "pve03"
  }

  "K8S-DMZ-01" = {
    tags             = ["talos", "dmz"]
    on_boot          = true
    agent            = true
    bios             = "seabios"
    cpu              = { cores = 2 }
    memory           = { dedicated = 4096 }
    operating_system = { type = "l26" }
    network_devices  = [{ vlan_id = 4, mac_address = "BC:24:11:A5:DF:59" }]
    disks = {
      "scsi0" = { size = 16 }
    }
    cdrom = {
      file_id = "remote-hdd:iso/talos-nocloud-amd64-qemu.iso"
    }
    talos = {
      cluster = "cluster-dmz"
      type    = "controlplane"
      patch_data = <<EOF
machine:
  network:
    hostname: k8s-dmz-01.internal
  nodeLabels:
    zone: dmz
EOF
    }
    node_name = "pve01"
  }

  "K8S-DMZ-02" = {
    tags             = ["talos", "dmz"]
    on_boot          = true
    agent            = true
    bios             = "seabios"
    cpu              = { cores = 2 }
    memory           = { dedicated = 4096 }
    operating_system = { type = "l26" }
    network_devices  = [{ vlan_id = 4, mac_address = "BC:24:11:5B:F5:38" }]
    disks = {
      "scsi0" = { size = 16 }
    }
    cdrom = {
      file_id = "remote-hdd:iso/talos-nocloud-amd64-qemu.iso"
    }
    talos = {
      cluster = "cluster-dmz"
      type    = "controlplane"
      patch_data = <<EOF
machine:
  network:
    hostname: k8s-dmz-02.internal
  nodeLabels:
    zone: dmz
EOF
    }
    node_name = "pve02"
  }

  "K8S-DMZ-03" = {
    tags             = ["talos", "dmz"]
    on_boot          = true
    agent            = true
    bios             = "seabios"
    cpu              = { cores = 2 }
    memory           = { dedicated = 4096 }
    operating_system = { type = "l26" }
    network_devices  = [{ vlan_id = 4, mac_address = "BC:24:11:B2:65:81" }]
    disks = {
      "scsi0" = { size = 16 }
    }
    cdrom = {
      file_id = "remote-hdd:iso/talos-nocloud-amd64-qemu.iso"
    }
    talos = {
      cluster = "cluster-dmz"
      type    = "controlplane"
      patch_data = <<EOF
machine:
  network:
    hostname: k8s-dmz-03.internal
  nodeLabels:
    zone: dmz
EOF
    }
    node_name = "pve03"
  }
}