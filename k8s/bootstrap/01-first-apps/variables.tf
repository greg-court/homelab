variable "bootstrap_repo_url"       { type = string }
variable "bootstrap_repo_path"      { type = string }
variable "bootstrap_repo_revision"  { type = string default = "main" }

variable "azure_tenant_id" { sensitive = true }
variable "azure_client_id" { sensitive = true }
variable "azure_client_secret" { sensitive = true }