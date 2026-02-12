locals {
  env = basename(get_terragrunt_dir())
  enable_alb_ingress_controller = false
  enable_argocd = false
  enable_argocd_image_updater = false
  enable_envoy_gateway_api = false
  enable_external_secrets_operator = false
  enable_aws_efs = false
  enable_aws_eks = true
  enable_aws_network = true
  enable_gha_runner = false
  enable_grafana = true
  enable_karpenter = true
  enable_kube_downscaler = false
  enable_prometheus = true
  enable_secrets_store_csi_driver = false
  enable_sonarqube = false
  enable_stakater_reloader = false
  tags = {
      project   = "eks-cluster"
      terraform = "true"
      env = local.env
  }
}
