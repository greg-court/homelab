pve_endpoint = "https://pve02.internal:8006/api2/json"
proxmox_users = {
  "ansible@pve" = {
    comment = "Automation user"
    acls = [
      { path = "/vms", role_id = "PVEVMAdmin" }
    ]
    tokens = {
      ansible-cd = {
        privileges_separation = false
      }
    }
  }
}
