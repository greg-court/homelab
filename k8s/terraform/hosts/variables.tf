variable "endpoint" { default = "https://pve02.internal:8006/api2/json" }

variable "disk_device" { default = "/dev/sda" }

variable "talos_version" { default = "v1.10.5" }

variable "talos_install_image" { default = "factory.talos.dev/installer/ce4c980550dd2ab1b17bbf2b08801c7eb59418eafe8f279833297925d67c7515:v1.10.5" }

variable "clusters" { type = any }