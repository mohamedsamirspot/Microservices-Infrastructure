data "aws_secretsmanager_secret_version" "monitoring_passcode" {
  secret_id = "terraform/github-token"
}

resource "kubectl_manifest" "monitoring_passcode" {
  yaml_body = <<-YAML
apiVersion: v1
kind: Secret
metadata:
  name: monitoring_passcode
  namespace: sonarqube
type: Opaque
data:
  pass-key: "${base64encode(jsondecode(data.aws_secretsmanager_secret_version.github_token.secret_string)["github-token"])}"
YAML
  depends_on = [helm_release.sonarqube]
}

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
