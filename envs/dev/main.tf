locals {
  # Always derive env from current folder
  env = basename(path.cwd)

  # Default tags for the environment
  default_tags = {
    env       = local.env
    terraform = "true"
  }
}

module "network" {
  source       = "../../modules/aws-network"
  cluster_name = "${local.env}-${var.cluster_name}"
  # Merge order: default_tags < root-specific extra tags < module defaults
  tags = local.default_tags
}

module "eks" {
  source                     = "../../modules/aws-eks"
  cluster_name               = var.cluster_name
  vpc_id                     = module.network.vpc_id
  subnet_ids                 = module.network.private_subnet_ids # Use private subnets for worker nodes
  # control_plane_subnet_ids = module.network.public_subnet_ids   # Public subnets for the control plane
  cluster_endpoint_public_access_cidrs = var.cluster_endpoint_public_access_cidrs

  tags = local.default_tags
}

module "karpenter" {
  source = "../../k8s-tools/karpenter"
  cluster_name    = module.eks.cluster_name
  kubernetes_version = module.eks.cluster_version
  cluster_endpoint = module.eks.cluster_endpoint

  # If you’re not using aliases or multiple configs, you can usually omit providers = {…} and let Terraform inject the root provider automatically.
  # providers = {
  #   helm = helm
  #   kubectl = kubectl
  # }

  depends_on = [ module.eks ]
  tags = local.default_tags
}

module "alb-ingress-controller" {
  source = "../../k8s-tools/alb-ingress-controller"
  vpcId             = module.network.vpc_id
  cluster_name      = module.eks.cluster_name
  oidc_provider_arn = module.eks.oidc_provider_arn

  depends_on = [ module.eks, module.karpenter ]
  tags = local.default_tags
}

module "argocd" {
  source = "../../k8s-tools/argocd"
  cluster_name      = module.eks.cluster_name

  depends_on = [ module.eks, module.karpenter ]
  tags = local.default_tags
}

# module "efs" {
#   source                      = "../../modules/aws-efs"
#   vpc_id                      = module.network.vpc_id 
#   private_subnets             = module.network.private_subnet_ids # Use private subnets for worker nodes
#   private_subnets_cidr_blocks = module.network.private_subnets_cidr_blocks
#   depends_on = [ module.network ]
#   tags = local.default_tags
# }