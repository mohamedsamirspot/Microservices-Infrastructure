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


resource "helm_release" "grafana" {
  name             = "grafana"
  repository       = "https://grafana.github.io/helm-charts"
  chart            = "grafana"
  version          = var.grafana_chart_version
  namespace        = "monitoring"
  create_namespace = true

  set_sensitive = {
    name  = "grafanaadminpassword"
    value = module.secrets_manager.secret_string
  }


  depends_on = [ module.secrets_manager ]
}
