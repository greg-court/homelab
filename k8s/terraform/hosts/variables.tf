variable "endpoint" {
  description = "Proxmox API endpoint"
  default     = "https://pve02:8006/api2/json"
}

variable "disk_device" {
  description = "Target disk inside the VM"
  default     = "/dev/sda"
}

variable "talos_version" {
  default = "v1.10.5"
}

variable "talos_install_image" {
  # You asked to hard-pin this build:
  default = "factory.talos.dev/installer/ce4c980550dd2ab1b17bbf2b08801c7eb59418eafe8f279833297925d67c7515:v1.10.5"
}

variable "clusters" {
  description = "Map of clusters with their nodes and configurations"
  type        = any
}