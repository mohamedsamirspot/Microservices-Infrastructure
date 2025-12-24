locals {
  env = basename(get_terragrunt_dir())
  enable_alb_ingress_controller = false
  enable_argocd = false
  enable_argocd_image_updater = false
  enable_eks = false
  enable_gha_runner = false
  enable_karpenter = false
  enable_network = false
  enable_stakater_reloader = false
}
