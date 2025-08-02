clusters = {
  trust = {
    vlan_id = 3
    nodes = {
      k8s-svc-01 = { mac = "BC:24:11:D2:72:43", pve_host = "pve01" }
      k8s-svc-02 = { mac = "BC:24:11:E2:67:FD", pve_host = "pve02" }
      k8s-svc-03 = { mac = "BC:24:11:CC:92:00", pve_host = "pve03" }
    }
  }
  dmz = {
    vlan_id = 4
    nodes = {
      k8s-dmz-01 = { mac = "BC:24:11:A5:DF:59", pve_host = "pve01" }
      k8s-dmz-02 = { mac = "BC:24:11:5B:F5:38", pve_host = "pve02" }
      k8s-dmz-03 = { mac = "BC:24:11:B2:65:81", pve_host = "pve03" }
    }
  }
}
