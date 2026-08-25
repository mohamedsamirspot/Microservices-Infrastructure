locals {
  env = basename(get_terragrunt_dir())
  enable_argocd = true
  enable_argocd_image_updater = true
  enable_aws_load_balancer_controller = true
  enable_envoy_gateway_api = true
  enable_external_secrets_operator = true
  enable_gateway_api_crds = true
  enable_aws_efs = true
  enable_aws_eks = true
  enable_aws_network = true
  enable_gha_runner = true
  enable_grafana = true
  enable_grafana_alloy = true
  enable_karpenter = true
  enable_kube_downscaler = true
  enable_loki = true
  enable_prometheus = true
  enable_blackbox_exporter = true
  enable_secrets_store_csi_driver = true
  enable_sonarqube = true
  enable_stakater_reloader = true
  tags = {
      project   = "eks-cluster"
      terraform = "true"
      env = local.env
  }
}
