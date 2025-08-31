resource "kubernetes_namespace" "external_secrets" {
  metadata { name = "external-secrets" }
  depends_on = [talos_cluster_kubeconfig.kc, null_resource.wait_for_api]
}

resource "kubernetes_secret" "azure_kv_creds" {
  metadata {
    name      = "azure-kv-creds"
    namespace = kubernetes_namespace.external_secrets.metadata[0].name
  }
  type = "Opaque"

  data = {
    client-id     = var.azure_client_id
    client-secret = var.azure_client_secret
    tenant-id     = var.azure_tenant_id
  }
  lifecycle { ignore_changes = [data] }
}