variable "endpoint" { default = "https://pve02.internal:8006/api2/json" }
variable "clusters" {
  description = "Per-cluster defaults and per-host deltas"
  type = map(object({
    vlan_id     = number
    zone        = string
    extra_tags  = optional(list(string), [])
    nameservers = optional(list(string))

    hosts = map(object({
      mac_address = string
      node_name   = string
      # optional extra disks per host (e.g., { scsi1 = { size = 32 }, scsi2 = { size = 64 } })
      disks = optional(map(object({ size = number })), {})
      # optional filesystem mounts managed by Talos
      mounts = optional(list(object({
        device  = string
        mount   = string
        fs      = optional(string)       # default xfs
        wipe    = optional(bool)         # default true
        options = optional(list(string)) # default ["noatime"]
      })), [])
    }))
  }))
}

variable "install_image" { default = "factory.talos.dev/installer/ce4c980550dd2ab1b17bbf2b08801c7eb59418eafe8f279833297925d67c7515:v1.10.5" }