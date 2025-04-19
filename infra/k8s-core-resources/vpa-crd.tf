locals {
  vpa_crd_docs = [
    for doc in split("\n---\n", data.http.vpa_crd.response_body) :
    trimspace(doc)
  ]
}

data "http" "vpa_crd" {
  url = "https://raw.githubusercontent.com/kubernetes/autoscaler/vpa-release-1.0/vertical-pod-autoscaler/deploy/vpa-v1-crd-gen.yaml"
}

resource "kubectl_manifest" "vpa_crd" {
  for_each = { for idx, doc in local.vpa_crd_docs : idx => doc }

  yaml_body = each.value

  ignore_fields = [
    "metadata.annotations",
    "metadata.labels",
    "status",
  ]
  validate_schema = false

}
