module "pve01" {
  source = "./pve01"
  root_password = var.pve01_pass
  endpoint = "https://pve01:8006/api2/json"
}

module "pve02" {
  source = "./pve02"
  root_password = var.pve02_pass
  endpoint = "https://pve02:8006/api2/json"
}

module "pve03" {
  source = "./pve03"
  root_password = var.pve03_pass
  endpoint = "https://pve03:8006/api2/json"
}