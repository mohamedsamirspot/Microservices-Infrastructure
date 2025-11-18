locals {
  github_app_id = "2314309"
  github_app_installation_id = "95382986"
}


# data "aws_ssm_parameter" "github_privatekey" {
#   name = "/dev/github_app_privatekey"
# }


resource "kubectl_manifest" "actions_namespace" {
  yaml_body = <<-YAML
apiVersion: v1
kind: Namespace
metadata:
  name: actions
YAML
}


resource "kubectl_manifest" "github_runner_secret" {
  depends_on = [kubectl_manifest.actions_namespace]

  yaml_body = <<-YAML
apiVersion: v1
kind: Secret
metadata:
  name: github-config
  namespace: actions
type: Opaque
data:
  github_app_id: "${local.github_app_id}"
  github_app_installation_id: "${local.github_app_installation_id}"
#   github_app_private_key: "${data.aws_ssm_parameter.github_privatekey.value}"
 github_app_private_key: "${base64encode(file("${path.module}/samirspot-arc-runner-controller.2025-11-18.private-key"))}"
YAML
}


# arc = actions runner controller
resource "helm_release" "arc_systems" {
  name       = "arc-systems"
  namespace  = kubectl_manifest.actions_namespace.metadata[0].name
  depends_on = [ kubectl_manifest.actions_namespace ]
  chart      = "gha-runner-scale-set-controller"
  repository = "oci://ghcr.io/actions/actions-runner-controller-charts"
  version    = "0.12.1"
}


resource "helm_release" "arc_runners" {
  name       = "gha-runner"
  namespace  = kubectl_manifest.actions_namespace.metadata[0].name
  depends_on = [ kubectl_manifest.actions_namespace, kubectl_manifest.github_runner_secret, helm_release.arc_systems ]
  chart      = "gha-runner-scale-set"
  repository = "oci://ghcr.io/actions/actions-runner-controller-charts"
  version    = "0.12.1"

  values = [
    yamlencode({
      githubConfigUrl    = "https://github.com/mohamedsamirspot"
      githubConfigSecret = kubernetes_secret_v1.github_runner_config.metadata[0].name
      containerMode = {
        type = "dind"
      }
    })
  ]
}