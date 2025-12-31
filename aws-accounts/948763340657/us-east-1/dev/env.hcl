locals {
  env = basename(get_terragrunt_dir())
  enable_alb_ingress_controller = true
  enable_argocd = true
  enable_argocd_image_updater = true
  enable_eks = true
  enable_gha_runner = true
  enable_karpenter = true
  enable_kube_downscaler = true
  enable_network = true
  enable_stakater_reloader = true
  tags = {
      project   = "eks-cluster"
      terraform = "true"
      env = local.env
  }
}
