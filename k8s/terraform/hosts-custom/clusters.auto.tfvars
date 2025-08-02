clusters = {
  cluster-trust = {
    vlan_id    = 3
    zone       = "infra"
    hosts = {
      k8s-trust-01 = {
        mac_address  = "BC:24:11:D2:72:43"
        node_name    = "pve02"
      }
      k8s-trust-02 = {
        mac_address  = "BC:24:11:E2:67:FD"
        node_name    = "pve02"
      }
      k8s-trust-03 = {
        mac_address  = "BC:24:11:CC:92:00"
        node_name    = "pve03"
      }
    }
  }
  cluster-dmz = {
    vlan_id    = 4
    zone       = "dmz"
    extra_tags = ["dmz"]
    hosts = {
       k8s-dmz-01 = {
        mac_address  = "BC:24:11:A5:DF:59"
        node_name    = "pve03"
      }
      k8s-dmz-02 = {
        mac_address  = "BC:24:11:5B:F5:38"
        node_name    = "pve02"
      }
      k8s-dmz-03 = {
        mac_address  = "BC:24:11:B2:65:81"
        node_name    = "pve03"
      }
    }
  }
}