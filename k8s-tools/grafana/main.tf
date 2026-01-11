module "secrets_manager" {
  source = "terraform-aws-modules/secrets-manager/aws"
  version = "2.1.0"

  # Secret
  name             = "grafana-admin-password"
  recovery_window_in_days = 0
  ignore_secret_changes = true

  # Policy
  create_policy       = false
  block_public_policy = true

  # Version
  create_random_password           = true
  random_password_length           = 64
  random_password_override_special = "!@#$%^&*()_+"

  tags = var.tags
}

data "aws_secretsmanager_secret_version" "grafana_admin" {
  secret_id = module.secrets_manager.secret_id
}

resource "helm_release" "grafana" {
  name             = "grafana"
  repository       = "https://grafana.github.io/helm-charts"
  chart            = "grafana"
  version          = var.grafana_chart_version
  namespace        = "monitoring"
  create_namespace = true

  values = [
    file("${path.module}/values-grafana.yaml")
  ]

  # set_sensitive can accept null during plan and will only resolve the value at apply time. You don’t need to use templatefile.
  set_sensitive {
    name  = "adminPassword"
    value = data.aws_secretsmanager_secret_version.grafana_admin.secret_string
  }

  depends_on = [ module.secrets_manager ]
}
