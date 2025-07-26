variable "zone_name" { type = string }
variable "records" {
  type = list(object({
    name     = string
    type     = string
    content  = string
    ttl      = number
    proxied  = optional(bool)
    priority = optional(number)
  }))
}
