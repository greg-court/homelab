variable "namespace" { default = "argocd" }
variable "chart_version" { default = "6.0.12" }
variable "extra_values_files" {
  type    = list(string)
  default = []
} # list of paths
variable "bootstrap_repo_url" {}
variable "bootstrap_repo_path" {}
variable "bootstrap_repo_revision" { default = "main" }