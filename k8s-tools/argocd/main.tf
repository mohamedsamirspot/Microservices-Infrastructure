resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  version          = var.argocd_chart_version
  namespace        = "argocd"
  create_namespace = true

  values = [
    file("${path.module}/values-argocd.yaml")
  ]

  # values = [yamlencode({
  #   serviceAccount = {
  #     create = false
  #     name   = "secrets-store-csi-driver"
  #   }
  # })]
}
