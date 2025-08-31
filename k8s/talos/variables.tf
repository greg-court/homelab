variable "cluster_name" { type = string }     # "homelab"
variable "install_disk" { type = string }     # "/dev/sda"
variable "cluster_endpoint" { type = string } # "https://k8s-01:6443"
variable "api_server" { type = string }       # "api.klab.internal"
variable "bootstrap_node" { type = string }   # "k8s-01"
variable "storage_account_name" { type = string }
variable "container_name" { type = string }

variable "azure_tenant_id" { sensitive = true }
variable "azure_client_id" { sensitive = true }
variable "azure_client_secret" { sensitive = true }

variable "hosts" {
  type = list(string)
  default = [
    "n1.klab.internal",
    "n2.klab.internal",
    "n3.klab.internal"
  ]
}