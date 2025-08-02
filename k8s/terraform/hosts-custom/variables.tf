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