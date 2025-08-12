variable "cluster_name"           { type = string } # "homelab"
variable "install_disk"           { type = string } # "/dev/sda"
variable "cluster_endpoint"       { type = string } # "https://k8s-01:6443"
variable "bootstrap_node"         { type = string } # "k8s-01"
variable "storage_account_name"   { type = string }
variable "container_name"         { type = string }

# Do bootstrap & fetch kubeconfig when true
variable "bootstrap"              { type = bool   default = false }
