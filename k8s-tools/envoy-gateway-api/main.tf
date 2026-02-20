# This chart include both the Envoy Gateway and Gateway API crds and you can skip the gateway api crds if you want to install them separately and i think it's better to install them separately if you have more than one gateway implementation in the cluster
# https://gateway.envoyproxy.io/v1.5/install/install-helm/

# https://gateway.envoyproxy.io/v1.5/install/gateway-crds-helm-api/
# The envoy gateway api custome crds like the EnvoyProxy and the EnvoyFilter
# crds.gatewayAPI.enabled=false this is the gateway api crds themeselves and we will install them separately in another module
data "helm_template" "custome_envoy_gateway_crds" {
  name       = "eg-crds"
  repository = "oci://docker.io/envoyproxy"
  chart      = "gateway-crds-helm"
  version    = "1.6.2"

  set {
    name  = "crds.gatewayAPI.enabled"
    value = "false"
  }

  set {
    name  = "crds.envoyGateway.enabled"
    value = "true"
  }
}
resource "kubectl_manifest" "envoy_gateway_crds" {
  for_each = data.helm_template.custome_envoy_gateway_crds.manifests  # <-- use .manifests not .manifest

  yaml_body         = each.value
  server_side_apply = true
  force_conflicts   = true
}


# https://gateway.envoyproxy.io/v1.5/install/gateway-helm-api/
# The envoy gateway api controller itself
resource "helm_release" "envoy-gateway-api" {
  name             = "envoy-gateway-api"
  repository       = "oci://docker.io/envoyproxy"
  chart            = "gateway-helm"
  version          = var.envoy-gateway-api_chart_version
  namespace        = "envoy-gateway-api"
  create_namespace = true
  skip_crds        = true
}
