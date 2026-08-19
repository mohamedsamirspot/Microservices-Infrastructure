resource "helm_release" "blackbox_exporter" {
  name             = "blackbox-exporter"
  repository       = "https://prometheus-community.github.io/helm-charts"
  chart            = "prometheus-blackbox-exporter"
  version          = var.blackbox_exporter_chart_version
  namespace        = "monitoring"
  create_namespace = true

  values = [
    file("${path.module}/values-blackbox-exporter.yaml")
  ]
}
