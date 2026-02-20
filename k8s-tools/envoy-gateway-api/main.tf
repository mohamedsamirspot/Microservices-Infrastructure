# This chart include both the Envoy Gateway and Gateway API crds and you can skip the gateway api crds if you want to install them separately and i think it's better to install them separately if you have more than one gateway implementation in the cluster
# https://gateway.envoyproxy.io/v1.5/install/install-helm/

# variable "custome_envoy_gateway_crds_chart_version" {
#   default = "1.6.2"
# }


# The envoy gateway api custome crds like the EnvoyProxy and the EnvoyFilter
# resource "kubectl_manifest" "envoy_gateway_custome_crds" {
#   for_each = toset(["eg-crds"])

#   yaml_body = <<EOT
# ${chomp(trimspace(shell("helm template ${each.key} oci://docker.io/envoyproxy/gateway-crds-helm \
#   --version ${var.custome_envoy_gateway_crds_chart_version} \
#   --set crds.gatewayAPI.enabled=false \
#   --set crds.envoyGateway.enabled=true")))}
# EOT
# }

# The controller itself
resource "helm_release" "envoy-gateway-api" {
  name             = "envoy-gateway-api"
  repository       = "oci://docker.io/envoyproxy"
  chart            = "gateway-helm"
  version          = var.envoy-gateway-api_chart_version
  namespace        = "envoy-gateway-api"
  create_namespace = true
  skip_crds        = true
}

