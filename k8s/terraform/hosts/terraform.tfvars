clusters = {
  trust = {
    vlan_id  = 3
    endpoint = "https://k8s-svc-01:6443"
    nodes = {                                                      # nodes in services vlan
      "k8s-svc-01" = { mac = "bc:24:11:d2:72:43", host = "pve02" } # temp while pve01 not available
      "k8s-svc-02" = { mac = "bc:24:11:e2:67:fd", host = "pve02" }
      "k8s-svc-03" = { mac = "bc:24:11:cc:92:00", host = "pve03" }
    }
    vlan_id = 3
  }
  dmz = {
    vlan_id  = 4
    endpoint = "https://k8s-dmz-01:6443"
    nodes = {                                                      # nodes in dmz vlan
      "k8s-dmz-01" = { mac = "bc:24:11:a5:df:59", host = "pve03" } # temp while pve01 not available
      "k8s-dmz-02" = { mac = "bc:24:11:5b:f5:38", host = "pve02" }
      "k8s-dmz-03" = { mac = "bc:24:11:b2:65:81", host = "pve03" }
    }
    vlan_id = 4
  }
}
