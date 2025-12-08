resource "helm_release" "argocd-image-updater" {
  name             = "argocd-image-updater"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argocd-image-updater"
  version          = var.argocd_chart_version
  namespace        = "argocd-image-updater"
  create_namespace = true

  values = [
    file("${path.module}/values-argocd-image-updater.yaml")
  ]

  # Example of inline value override
  # set {
  #   name  = "server.service.type"
  #   value = "LoadBalancer"
  # }
}