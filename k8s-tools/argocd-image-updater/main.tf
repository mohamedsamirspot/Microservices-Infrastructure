data "aws_secretsmanager_secret_version" "github_token" {
  secret_id = "terraform/github-token"
}

resource "kubectl_manifest" "gh_auth_token" {
  yaml_body = <<-YAML
apiVersion: v1
kind: Secret
metadata:
  name: git-creds
  namespace: argocd
type: Opaque
data:
  username: "${base64encode("mohamedsamirspot")}"
  password: "${base64encode(jsondecode(data.aws_secretsmanager_secret_version.github_token.secret_string)["github-token"])}"
YAML
  depends_on = [helm_release.argocd-image-updater]
}

resource "helm_release" "argocd-image-updater" {
  name             = "argocd-image-updater"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argocd-image-updater"
  version          = var.argocd-image-updater_chart_version
  namespace        = "argocd"
  create_namespace = true

  # values = [
  #   file("${path.module}/values-argocd-image-updater.yaml")
  # ]

  # Example of inline value override
  # set {
  #   name  = "server.service.type"
  #   value = "LoadBalancer"
  # }
}