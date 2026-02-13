# module "secrets_manager" {
#   source = "terraform-aws-modules/secrets-manager/aws"
#   version = "2.1.0"

#   # Secret
#   name             = "grafana-admin-password"
#   recovery_window_in_days = 0
#   ignore_secret_changes = true

#   # Policy
#   create_policy       = false
#   block_public_policy = true

#   # Version
#   create_random_password           = true
#   random_password_length           = 64
#   random_password_override_special = "!@#$%^&*()_+"

#   tags = var.tags
# }

# data "aws_secretsmanager_secret_version" "grafana_admin" {
#   secret_id  = module.secrets_manager.secret_id
#   version_id = module.secrets_manager.secret_version_id
# }

resource "kubectl_manifest" "monitoring_namespace" {
  yaml_body = <<-YAML
apiVersion: v1
kind: Namespace
metadata:
  name: monitoring
YAML
}

# Generate a random password for Grafana admin
resource "random_password" "grafana_admin_password" {
  length  = 24
  special = true
  upper   = true
  lower   = true
  numeric = true
}

# Create Kubernetes secret for Grafana admin credentials
resource "kubectl_manifest" "grafana_admin_secret" {
  yaml_body = <<-YAML
apiVersion: v1
kind: Secret
metadata:
  name: grafana-admin-credentials
  namespace: monitoring
type: Opaque
stringData:
  userKey: admin
  passwordKey: ${random_password.grafana_admin_password.result}
YAML

  depends_on = [kubectl_manifest.monitoring_namespace]
}

resource "kubectl_manifest" "grafana-configmaps" {
  for_each = fileset("${path.module}/grafana-configmaps", "*.yaml")

  yaml_body = file("${path.module}/grafana-configmaps/${each.value}")

  depends_on = [kubectl_manifest.monitoring_namespace]
}

resource "helm_release" "grafana" {
  name             = "grafana"
  repository       = "https://grafana.github.io/helm-charts"
  chart            = "grafana"
  version          = var.grafana_chart_version
  namespace        = "monitoring"
  create_namespace = true

  # values = [
  #   templatefile("${path.module}/values-grafana.yaml", {
  #       grafanaadminpassword      = data.aws_secretsmanager_secret_version.grafana_admin.secret_string
  #     })
  # ]
  values = [
    file("${path.module}/values-grafana.yaml")
  ]
  # depends_on = [ module.secrets_manager]
  depends_on = [kubectl_manifest.grafana_admin_secret]
}
