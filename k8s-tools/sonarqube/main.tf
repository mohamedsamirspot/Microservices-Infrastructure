resource "helm_release" "sonarqube" {
  name             = "sonarqube"
  repository       = "https://SonarSource.github.io/helm-chart-sonarqube"
  chart            = "sonarqube"
  version          = var.sonarqube_chart_version
  namespace        = "sonarqube"
  create_namespace = true

  values = [
    file("${path.module}/values-sonarqube.yaml")
  ]

  # Example of inline value override
  # set {
  #   name  = "server.service.type"
  #   value = "LoadBalancer"
  # }
}
