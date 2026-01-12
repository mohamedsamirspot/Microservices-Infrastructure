resource "helm_release" "prometheus" {
  name             = "prometheus"
  repository       = "https://prometheus-community.github.io/helm-charts"
  chart            = "prometheus"
  version          = var.prometheus_chart_version
  namespace        = "monitoring"
  create_namespace = true

  values = [
    file("${path.module}/values-prometheus.yaml")
  ]
}
