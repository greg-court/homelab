variable "azure_tenant_id" { sensitive = true }
variable "azure_client_id" { sensitive = true }
variable "azure_client_secret" { sensitive = true }

# Make sure the namespace exists (Argo will happily reuse it)
resource "kubernetes_namespace" "external_secrets" {
  metadata { name = "external-secrets" }
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