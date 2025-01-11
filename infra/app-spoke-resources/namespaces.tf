resource "kubernetes_namespace" "cob" {
  metadata {
    name = local.k8s_namespace

    labels = {
      provisioned_by = "terraform"
    }
  }
}
