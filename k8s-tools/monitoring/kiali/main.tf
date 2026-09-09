resource "helm_release" "kiali" {
  name             = "kiali-server"
  repository       = "https://kiali.org/helm-charts"
  chart            = "kiali-server"
  version          = var.kiali_chart_version
  namespace        = "monitoring"
  create_namespace = true

  values = [
    file("${path.module}/values-kiali.yaml")
  ]
}
