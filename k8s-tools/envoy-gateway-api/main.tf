# This chart include both the Envoy Gateway and Gateway API crds and you can skip the gateway api crds if you want to install them separately and i think it's better to install them separately if you have more than one gateway implementation in the cluster
# https://gateway.envoyproxy.io/v1.5/install/install-helm/

resource "helm_release" "envoy-gateway-api" {
  name             = "envoy-gateway-api"
  repository       = "oci://docker.io/envoyproxy"
  chart            = "gateway-helm"
  version          = var.envoy-gateway-api_chart_version
  namespace        = "envoy-gateway-api"
  create_namespace = true
  skip_crds        = true
}
