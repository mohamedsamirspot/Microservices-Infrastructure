data "http" "gateway_api_crds" {
  url = "https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.6.0/standard-install.yaml"
}

resource "kubectl_manifest" "gateway_api_crds" {
  for_each = { for idx, manifest in split("---", data.http.gateway_api_crds.response_body) :
    "${idx}-${md5(manifest)}" => manifest
    if trimspace(manifest) != "" && can(yamldecode(manifest))
  }

  yaml_body = each.value

  # Use server-side apply to avoid annotation size limits in t he httproute
  server_side_apply = true
  force_conflicts    = true
}
