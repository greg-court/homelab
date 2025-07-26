variable "docker_host" {
  default = null
}
variable "container_instances" {
  default = {}
}
variable "gh_homelab_admin_pat" {
  default   = null
  sensitive = true
}
variable "gh_homelab_repo_url" {
  default = null
}
variable "tfc_agent_token" {
  default   = null
  sensitive = true
}
variable "replace_dirs" {
  type        = map(string)
  default     = {}
  description = "Map of 'container_type.instance_name' => directory path; triggers recreation on file changes"
}