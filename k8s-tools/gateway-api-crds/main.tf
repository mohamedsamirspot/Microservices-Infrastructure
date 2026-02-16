resource "kubectl_manifest" "gateway_api_crds" {
  yaml_body = <<-EOF
  ${file("https://raw.githubusercontent.com/kubernetes-sigs/gateway-api/v1.4.1/config/standard-install.yaml")}
  EOF
}
