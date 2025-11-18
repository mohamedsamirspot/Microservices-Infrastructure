
locals {
  # Version of the ArgoCD Helm chart
  argocd_chart_version = "9.0.5"
}

resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  version          = local.argocd_chart_version
  namespace        = "argocd"
  create_namespace = true

  values = [
    file("${path.module}/values-argocd.yaml")
  ]

  # Example of inline value override
  # set {
  #   name  = "server.service.type"
  #   value = "LoadBalancer"
  # }
}