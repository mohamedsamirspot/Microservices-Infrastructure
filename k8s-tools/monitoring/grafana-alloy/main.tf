resource "helm_release" "grafana_alloy" {
  name             = "grafana-alloy"
  repository       = "https://grafana.github.io/helm-charts"
  chart            = "alloy"
  version          = var.alloy_chart_version != "" ? var.alloy_chart_version : null
  namespace        = "monitoring"
  create_namespace = true

  values = [
    templatefile("${path.module}/values-grafana-alloy.yaml", {
      loki_push_api_url         = var.loki_push_api_url
      cluster_name              = var.cluster_name
      namespace_selector_regex  = var.namespace_selector_regex
      enable_service_monitor    = var.enable_service_monitor
    })
  ]
}
