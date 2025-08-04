pve_endpoint = "https://pve02.internal:8006/api2/json"
proxmox_users = {
  "ansible@pve" = {
    comment = "Automation user"
    acls = [
      { path = "/", role_id = "PVEAdmin" }
    ]
    tokens = {
      ansible-cd = {
        privileges_separation = false
      }
    }
  }
}
