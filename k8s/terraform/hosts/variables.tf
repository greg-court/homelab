variable "endpoint" { default = "https://pve02.internal:8006/api2/json" }
variable "clusters" {
  description = "Per-cluster defaults and per-host deltas"
  type = map(object({
    vlan_id    = number
    zone       = string
    extra_tags = optional(list(string), [])

    hosts = map(object({
      mac_address = string
      node_name   = string
    }))
  }))
}

variable "install_image" { default = "factory.talos.dev/installer/ce4c980550dd2ab1b17bbf2b08801c7eb59418eafe8f279833297925d67c7515:v1.10.5" }