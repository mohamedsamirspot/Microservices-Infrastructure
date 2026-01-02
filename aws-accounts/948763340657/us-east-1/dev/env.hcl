locals {
  env = basename(get_terragrunt_dir())
  enable_alb_ingress_controller = false
  enable_argocd = false
  enable_argocd_image_updater = false
  enable_aws_efs = false
  enable_aws_eks = false
  enable_aws_network = true
  enable_gha_runner = false
  enable_karpenter = false
  enable_kube_downscaler = false
  enable_sonarqube = true
  enable_stakater_reloader = false
  tags = {
      project   = "eks-cluster"
      terraform = "true"
      env = local.env
  }
}
