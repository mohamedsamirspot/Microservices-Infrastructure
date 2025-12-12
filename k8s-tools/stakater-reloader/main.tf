resource "helm_release" "stakater-reloader" {
  name             = "stakater-reloader"
  repository       = "https://stakater.github.io/stakater-charts"
  chart            = "stakater/reloader"
  version          = var.stakater-reloader_chart_version
  namespace        = "stakater-reloader"
  create_namespace = true
}