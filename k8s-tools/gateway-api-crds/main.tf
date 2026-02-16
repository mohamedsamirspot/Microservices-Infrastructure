data "http" "gateway_api_crds" {
  url = "https://raw.githubusercontent.com/kubernetes-sigs/gateway-api/v1.4.1/config/standard-install.yaml"
}

resource "kubectl_manifest" "gateway_api_crds" {
  yaml_body = data.http.gateway_api_crds.response_body
}
