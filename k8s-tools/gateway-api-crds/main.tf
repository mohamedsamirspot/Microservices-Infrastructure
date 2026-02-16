data "http" "gateway_api_crds" {
  url = "https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.4.1/standard-install.yaml"
}

resource "kubectl_manifest" "gateway_api_crds" {
  for_each = { for manifest in split("---", data.http.gateway_api_crds.response_body) : 
    try(yamldecode(manifest).metadata.name, md5(manifest)) => manifest
    if trimspace(manifest) != "" && can(yamldecode(manifest))
  }
  
  yaml_body = each.value
}
