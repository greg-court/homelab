# resource "talos_machine_secrets" "trust" {}

# data "talos_client_configuration" "trust" {
#   cluster_name         = "cluster-trust"
#   client_configuration = talos_machine_secrets.trust.client_configuration
#   nodes                = [for hostname, _ in var.clusters.trust.nodes : "${hostname}.internal"]
# }

# # Generate a control-plane config for every node
# data "talos_machine_configuration" "trust_cp" {
#   for_each         = var.clusters.trust.nodes
#   cluster_name     = "cluster-trust"
#   machine_type     = "controlplane"
#   cluster_endpoint = var.clusters.trust.endpoint
#   machine_secrets  = talos_machine_secrets.trust.machine_secrets
# }

# # Push config + custom patches (installer image, allow scheduling, hostname)
# resource "talos_machine_configuration_apply" "trust_cp" {
#   for_each                    = data.talos_machine_configuration.trust_cp
#   client_configuration        = talos_machine_secrets.trust.client_configuration
#   machine_configuration_input = each.value.machine_configuration
#   node                        = "${each.key}.internal"

#   config_patches = [
#     yamlencode({
#       machine = {
#         install = {
#           disk  = var.disk_device
#           image = var.talos_install_image
#         }
#         network = {
#           hostname = each.key # k8s-ctrl-trust0X
#         }
#         nodeLabels = { zone = "svc" }
#       }
#       cluster = {
#         allowSchedulingOnControlPlanes = true
#       }
#     })
#   ]
# }

# # Bootstrap only one of the nodes
# resource "talos_machine_bootstrap" "trust" {
#   depends_on           = [talos_machine_configuration_apply.trust_cp]
#   node                 = "k8s-svc-01.internal"
#   client_configuration = talos_machine_secrets.trust.client_configuration
# }


# # Grab the kubeconfig once etcd is up
# resource "talos_cluster_kubeconfig" "trust" {
#   depends_on           = [talos_machine_bootstrap.trust]
#   client_configuration = talos_machine_secrets.trust.client_configuration
#   node                 = "k8s-svc-01.internal"
# }

# # Optionally write both artifacts to disk
# resource "local_sensitive_file" "trust_kubeconfig" {
#   filename = "${path.module}/cluster-trust/kubeconfig"
#   content  = talos_cluster_kubeconfig.trust.kubeconfig_raw
# }

# resource "local_sensitive_file" "trust_talosconfig" {
#   filename = "${path.module}/cluster-trust/talosconfig"
#   content  = yamlencode(talos_machine_secrets.trust.client_configuration)
# }
