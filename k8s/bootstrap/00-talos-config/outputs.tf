output "client_configuration" {
  value     = talos_machine_secrets.cluster.client_configuration
  sensitive = true
}

output "bootstrap_node" {
  value = var.bootstrap_node
}

output "cluster_name" {
  value = var.cluster_name
}
