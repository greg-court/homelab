hosts = {
  "K8S-CTRL-TRUST01" = {
    tags             = ["talos"]
    on_boot          = true
    agent            = true
    bios             = "seabios"
    cpu              = { cores = 1 }
    memory           = { dedicated = 2048 }
    operating_system = { type = "l26" }
    network_devices  = [{ vlan_id = 10, mac_address = "BC:24:11:D2:72:43" }]
    disks = {
      "scsi0" = { size = 16 }
    }
    cdrom = {
      file_id = "remote-hdd:iso/talos-nocloud-amd64-qemu.iso"
    }
    talos = {
      cluster = "cluster-trust"
      type    = "controlplane"
      # setting hostname in pfsense dhcp static lease
      patch_data = <<EOF
machine:
  network:
    hostname: k8s-ctrl-trust01.internal
  nodeLabels:
    zone: infra
EOF
    }
    node_name = "pve01"
  }

  "K8S-CTRL-TRUST02" = {
    tags             = ["talos"]
    on_boot          = true
    agent            = true
    bios             = "seabios"
    cpu              = { cores = 1 }
    memory           = { dedicated = 2048 }
    operating_system = { type = "l26" }
    network_devices  = [{ vlan_id = 10, mac_address = "BC:24:11:E2:67:FD" }]
    disks = {
      "scsi0" = { size = 16 }
    }
    cdrom = {
      file_id = "remote-hdd:iso/talos-nocloud-amd64-qemu.iso"
    }
    talos = {
      cluster = "cluster-trust"
      type    = "controlplane"
      # setting hostname in pfsense dhcp static lease
      patch_data = <<EOF
machine:
  network:
    hostname: k8s-ctrl-trust02.internal
  nodeLabels:
    zone: infra
EOF
    }
    node_name = "pve02"
  }

  "K8S-CTRL-TRUST03" = {
    tags             = ["talos"]
    on_boot          = true
    agent            = true
    bios             = "seabios"
    cpu              = { cores = 1 }
    memory           = { dedicated = 2048 }
    operating_system = { type = "l26" }
    network_devices  = [{ vlan_id = 10, mac_address = "BC:24:11:CC:92:00" }]
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
    hostname: k8s-ctrl-trust03.internal
  nodeLabels:
    zone: infra
EOF
    }
    node_name = "pve03"
  }

  "K8S-INFRA01" = {
    tags             = ["talos"]
    on_boot          = true
    agent            = true
    bios             = "seabios"
    cpu              = { cores = 1 }
    memory           = { dedicated = 2048 }
    operating_system = { type = "l26" }
    network_devices  = [{ vlan_id = 10, mac_address = "BC:24:11:40:3C:32" }]
    disks = {
      "scsi0" = { size = 16 }
    }
    cdrom = {
      file_id = "remote-hdd:iso/talos-nocloud-amd64-qemu.iso"
    }
    talos = {
      cluster    = "cluster-trust"
      type       = "worker"
      patch_data = <<EOF
machine:
  network:
    hostname: k8s-infra01.internal
  nodeLabels:
    zone: infra
    "node-role.kubernetes.io/worker": ""
EOF
    }
    node_name = "pve01"
  }

  "K8S-INFRA02" = {
    tags             = ["talos"]
    on_boot          = true
    agent            = true
    bios             = "seabios"
    cpu              = { cores = 1 }
    memory           = { dedicated = 2048 }
    operating_system = { type = "l26" }
    network_devices  = [{ vlan_id = 10, mac_address = "BC:24:11:94:C0:83" }]
    disks = {
      "scsi0" = { size = 16 }
    }
    cdrom = {
      file_id = "remote-hdd:iso/talos-nocloud-amd64-qemu.iso"
    }
    talos = {
      cluster    = "cluster-trust"
      type       = "worker"
      patch_data = <<EOF
machine:
  network:
    hostname: k8s-infra02.internal
  nodeLabels:
    zone: infra
    "node-role.kubernetes.io/worker": ""
EOF
    }
    node_name = "pve02"
  }

  "K8S-INFRA03" = {
    tags             = ["talos"]
    on_boot          = true
    agent            = true
    bios             = "seabios"
    cpu              = { cores = 1 }
    memory           = { dedicated = 2048 }
    operating_system = { type = "l26" }
    network_devices  = [{ vlan_id = 10, mac_address = "BC:24:11:2B:3F:4A" }]
    disks = {
      "scsi0" = { size = 16 }
    }
    cdrom = {
      file_id = "remote-hdd:iso/talos-nocloud-amd64-qemu.iso"
    }
    talos = {
      cluster    = "cluster-trust"
      type       = "worker"
      patch_data = <<EOF
machine:
  network:
    hostname: k8s-infra03.internal
  nodeLabels:
    zone: infra
    "node-role.kubernetes.io/worker": ""
EOF
    }
    node_name = "pve03"
  }

  "K8S-CTRL-DMZ01" = {
    tags             = ["talos", "dmz"]
    on_boot          = true
    agent            = true
    bios             = "seabios"
    cpu              = { cores = 1 }
    memory           = { dedicated = 2048 }
    operating_system = { type = "l26" }
    network_devices  = [{ vlan_id = 60, mac_address = "BC:24:11:A5:DF:59" }]
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
    hostname: k8s-ctrl-dmz01.internal
  nodeLabels:
    zone: dmz
EOF
    }
    node_name = "pve01"
  }

  "K8S-CTRL-DMZ02" = {
    tags             = ["talos", "dmz"]
    on_boot          = true
    agent            = true
    bios             = "seabios"
    cpu              = { cores = 1 }
    memory           = { dedicated = 2048 }
    operating_system = { type = "l26" }
    network_devices  = [{ vlan_id = 60, mac_address = "BC:24:11:5B:F5:38" }]
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
    hostname: k8s-ctrl-dmz02.internal
  nodeLabels:
    zone: dmz
EOF
    }
    node_name = "pve02"
  }

  "K8S-CTRL-DMZ03" = {
    tags             = ["talos", "dmz"]
    on_boot          = true
    agent            = true
    bios             = "seabios"
    cpu              = { cores = 1 }
    memory           = { dedicated = 2048 }
    operating_system = { type = "l26" }
    network_devices  = [{ vlan_id = 60, mac_address = "BC:24:11:B2:65:81" }]
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
    hostname: k8s-ctrl-dmz03.internal
  nodeLabels:
    zone: dmz
EOF
    }
    node_name = "pve03"
  }

  "K8S-DMZ01" = {
    tags             = ["talos", "dmz"]
    on_boot          = true
    agent            = true
    bios             = "seabios"
    cpu              = { cores = 1 }
    memory           = { dedicated = 2048 }
    operating_system = { type = "l26" }
    network_devices  = [{ vlan_id = 60, mac_address = "BC:24:11:13:06:A5" }]
    disks = {
      "scsi0" = { size = 16 }
    }
    cdrom = {
      file_id = "remote-hdd:iso/talos-nocloud-amd64-qemu.iso"
    }
    talos = {
      cluster    = "cluster-dmz"
      type       = "worker"
      patch_data = <<EOF
machine:
  network:
    hostname: k8s-dmz01.internal
  nodeLabels:
    zone: dmz
    "node-role.kubernetes.io/worker": ""
EOF
    }
    node_name = "pve01"
  }

  "K8S-DMZ02" = {
    tags             = ["talos", "dmz"]
    on_boot          = true
    agent            = true
    bios             = "seabios"
    cpu              = { cores = 1 }
    memory           = { dedicated = 2048 }
    operating_system = { type = "l26" }
    network_devices  = [{ vlan_id = 60, mac_address = "BC:24:11:DD:53:67" }]
    disks = {
      "scsi0" = { size = 16 }
    }
    cdrom = {
      file_id = "remote-hdd:iso/talos-nocloud-amd64-qemu.iso"
    }
    talos = {
      cluster    = "cluster-dmz"
      type       = "worker"
      patch_data = <<EOF
machine:
  network:
    hostname: k8s-dmz02.internal
  nodeLabels:
    zone: dmz
    "node-role.kubernetes.io/worker": ""
EOF
    }
    node_name = "pve02"
  }

  "K8S-DMZ03" = {
    tags             = ["talos", "dmz"]
    on_boot          = true
    agent            = true
    bios             = "seabios"
    cpu              = { cores = 1 }
    memory           = { dedicated = 2048 }
    operating_system = { type = "l26" }
    network_devices  = [{ vlan_id = 60, mac_address = "BC:24:11:2D:C0:33" }]
    disks = {
      "scsi0" = { size = 16 }
    }
    cdrom = {
      file_id = "remote-hdd:iso/talos-nocloud-amd64-qemu.iso"
    }
    talos = {
      cluster    = "cluster-dmz"
      type       = "worker"
      patch_data = <<EOF
machine:
  network:
    hostname: k8s-dmz03.internal
  nodeLabels:
    zone: dmz
    "node-role.kubernetes.io/worker": ""
EOF
    }
    node_name = "pve03"
  }
}