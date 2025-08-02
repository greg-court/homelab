variable "endpoint" { default = "https://pve02.internal:8006/api2/json" }

variable "disk_device" { default = "/dev/sda" }

variable "clusters" { type = any }