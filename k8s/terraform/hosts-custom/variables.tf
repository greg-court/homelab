variable "endpoint" { default = "https://pve01.internal:8006/api2/json" }
variable "clusters" {
  description = "Hierarchical VM declaration grouped by cluster"
  type        = any
}