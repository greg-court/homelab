variable "vms" { type = any }
variable "talos_templates_dir" {
  description = "Filesystem path to the Talos template directory; cluster sub-folders live beneath this path."
  type        = string
}